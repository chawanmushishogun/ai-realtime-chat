class ExportsController < ApplicationController
  layout "export"
  before_action :set_conversation

  def show
    fmt = params[:f].presence_in(%w[md html pdf]) || "md"
    case fmt
    when "md"
      send_data Ai::MarkdownExporter.new(@conversation).call, filename: filename("md"), type: "text/markdown; charset=utf-8"
    when "html"
      html = render_to_string template: "exports/show", layout: "export", formats: [:html]
      send_data html, filename: filename("html"), type: "text/html; charset=utf-8"
    when "pdf"
      render pdf: filename("pdf").sub(/\.pdf\z/, ""),
             template: "exports/show", layout: "export",
             encoding: "UTF-8", print_media_type: true, dpi: 300
    end
  end

  private

  def set_conversation = @conversation = current_user.conversations.find(params[:id])
  def filename(ext) = (@conversation.title.presence || "conversation_#{@conversation.id}").gsub(/[\s\\\/]/, "_") + ".#{ext}"
end
