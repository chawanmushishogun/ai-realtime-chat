class Ai::StreamingChat
  Result = Struct.new(:text, :finish_reason, keyword_init: true)

  DEFAULT_MODEL = "gemini-2.5-flash"

  def initialize(conversation_id:, stream_key: nil)
    @conversation_id = conversation_id.presence || "global"
    @stream_key = stream_key.presence || "chat_#{@conversation_id}"
    @stop_flag_key = "stop:#{@conversation_id}"
  end

  # messages: [{role: "system"|"user"|"assistant", content: "..."}, ...]
  def call!(messages, model: DEFAULT_MODEL, **opts)
    client = build_client(model)
    payload = build_payload(messages, opts)

    full_text = +""
    finish_reason = nil

    broadcast(event: "start", body: "")

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    first_delta_at = nil

    client.stream_generate_content(payload) do |event, _parsed, _raw|
      break if stop_requested?

      delta = event.dig("candidates", 0, "content", "parts", 0, "text")

      if delta
        if !first_delta_at
          first_delta_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          Rails.logger.info(event: "ttft", ms: ((first_delta_at - started) * 1000).round,
                            model: model, convo: @conversation_id, stream_key: @stream_key)
        end

        full_text << delta
        broadcast(event: "delta", body: delta)
      end

      fr = event.dig("candidates", 0, "finishReason")
      finish_reason = fr if fr
    end

    broadcast(event: "done", body: "", meta: { finish_reason: finish_reason })
    Result.new(text: full_text, finish_reason: finish_reason)
  rescue => e
    broadcast(event: "error", body: e.message)
    raise
  ensure
    clear_stop!
  end

  def request_stop!
    redis.setex(@stop_flag_key, 600, "1")
  end

  private

  def build_client(model)
    Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: Rails.application.credentials.dig(:gemini, :api_key),
        version: "v1beta"
      },
      options: { model: model, server_sent_events: true }
    )
  end

  def build_payload(messages, opts)
    system_text = messages.select { |m| m[:role].to_s == "system" }.map { |m| m[:content] }.join("\n")
    contents = messages.reject { |m| m[:role].to_s == "system" }.map do |m|
      { role: m[:role].to_s == "assistant" ? "model" : "user", parts: to_parts(m[:content]) }
    end

    payload = { contents: contents }
    payload[:system_instruction] = { role: "user", parts: { text: system_text } } if system_text.present?

    generation_config = {
      temperature: opts[:temperature],
      topP: opts[:top_p],
      presencePenalty: opts[:presence_penalty],
      frequencyPenalty: opts[:frequency_penalty]
    }.compact
    payload[:generationConfig] = generation_config if generation_config.present?

    payload
  end

  # content は文字列（プレーンテキスト）か、Gemini の parts 配列（マルチモーダル）を受け付ける
  def to_parts(content)
    content.is_a?(Array) ? content : [{ text: content }]
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/1"))
  end

  def stop_requested?
    redis.get(@stop_flag_key) == "1"
  end

  def clear_stop!
    redis.del(@stop_flag_key)
  end

  def broadcast(payload)
    ActionCable.server.broadcast(@stream_key, payload)
  end
end
