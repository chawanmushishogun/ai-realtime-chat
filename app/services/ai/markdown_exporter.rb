class Ai::MarkdownExporter
  def initialize(conversation) = @conversation = conversation

  def call
    lines = ["# #{title}", "", "- Exported: #{Time.current.iso8601}", "- Messages: #{@conversation.messages.count}", ""]
    @conversation.messages.order(:created_at).each do |m|
      lines << "## [#{m.role}] #{m.created_at.strftime('%Y-%m-%d %H:%M')}"
      lines << ""
      lines << code_safe(m.content)
      lines << ""
    end
    lines.join("\n")
  end

  private

  def title = @conversation.title.presence || "Conversation ##{@conversation.id}"

  # ```が奇数個なら仮閉じ（8章で見た手法の再利用）
  def code_safe(text)
    s = text.to_s
    s += "\n```" if s.scan("```").length.odd?
    s
  end
end
