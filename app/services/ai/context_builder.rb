class Ai::ContextBuilder
  DEFAULT_LIMIT = 20

  def initialize(conversation, limit: DEFAULT_LIMIT)
    @conversation = conversation
    @limit = limit
  end

  def build_with(latest_user_content)
    history = @conversation.last_messages(@limit)
    messages = [{ role: "system", content: @conversation.system_prompt }]
    messages += history.map { |m| { role: m.role, content: m.content } }
    messages << { role: "user", content: latest_user_content }
    messages
  end
end
