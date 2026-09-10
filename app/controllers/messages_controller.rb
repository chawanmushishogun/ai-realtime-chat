class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    limiter = RateLimiter.new(namespace: "messages", limit: 20, period: 60)
    unless limiter.allowed?(current_user.id)
      stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
      ActionCable.server.broadcast(stream_key, { event: "error", body: "Rate limit exceeded. Please wait." })
      head :too_many_requests and return
    end

    content = params.require(:message)[:content]
    files = Array(params.dig(:message, :files)).reject(&:blank?)

    user_msg = @conversation.messages.create!(role: :user, content: content)
    files.each { |f| user_msg.files.attach(f) }

    stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"

    result = if user_msg.files.attached?
      info = Attachments::Extractor.new.call(user_msg.files)
      Ai::AttachmentSummarizer.new(conversation: @conversation, stream_key: stream_key).call!(info)
    else
      messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(content)
      Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key)
                       .call!(messages, **@conversation.params_for_gemini)
    end

    @conversation.touch
    @conversation.messages.create!(role: :assistant, content: result.text, meta: { finish_reason: result.finish_reason })

    if @conversation.title.blank? || @conversation.title == "New conversation" || @conversation.title == "Default Conversation"
      begin
        title = Ai::TitleGenerator.new(@conversation).call
        @conversation.update!(title: title) if title.present?
      rescue => e
        Rails.logger.warn(auto_title_error: e.message)
      end
    end

    head :ok
  end

  def stop
    Ai::StreamingChat.new(conversation_id: @conversation.id).request_stop!
    head :ok
  end

  def regenerate
    last_user = @conversation.messages.where(role: :user).reorder(created_at: :desc).first
    return head :unprocessable_entity unless last_user

    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(last_user.content)
    stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
    opts = @conversation.params_for_gemini

    result = Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key).call!(messages, **opts)
    @conversation.touch
    @conversation.messages.create!(role: :assistant, content: result.text, meta: { finish_reason: result.finish_reason })
    head :ok
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end
end
