class Ai::TitleGenerator
  LIMIT = 20

  def initialize(conversation, sample: 6)
    @conversation = conversation
    @sample = sample
  end

  def call(model: "gemini-2.5-flash")
    recent = @conversation.messages.reorder(created_at: :desc).limit(@sample).to_a.reverse
    body = recent.map { |m| "[#{m.role}] #{m.content}" }.join("\n")

    sys = <<~SYS
      あなたは会話の要約タイトルを1行で作るアシスタントです。
      条件: 日本語 / 20字以内 / 絵文字・記号・括弧なし / 具体性重視 / 名詞句で簡潔に。
      出力はタイトルのみ（前後の説明や引用符を含めない）。
    SYS

    client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: Rails.application.credentials.dig(:gemini, :api_key),
        version: "v1beta"
      },
      options: { model: model }
    )

    result = client.generate_content({
      contents: { role: "user", parts: { text: body } },
      system_instruction: { role: "user", parts: { text: sys } },
      generationConfig: { temperature: 0.3 }
    })

    title = result.dig("candidates", 0, "content", "parts", 0, "text").to_s.strip
    normalize(title)
  end

  private

  def normalize(s)
    s = s.gsub(/[\p{Cf}\p{C}]/, "").gsub(/[\r\n]+/, " ").strip
    s = s.gsub(/["'「」\[\]()（）【】]/, "")
    s.size > LIMIT ? s[0, LIMIT] : s
  end
end
