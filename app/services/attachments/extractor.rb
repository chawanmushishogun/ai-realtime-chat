module Attachments
  class Extractor
    MAX_PAGES = Integer(ENV.fetch("PDF_SUMMARY_PAGES", 6))
    MAX_CHARS = Integer(ENV.fetch("ATTACH_TEXT_LIMIT", 8000))

    def call(attachments)
      Array(attachments).map { |att| extract_one(att) }.compact
    end

    private

    def extract_one(att)
      ct = att.content_type.to_s
      if ct.start_with?("image/")
        blob = att.download
        base64 = Base64.strict_encode64(blob)
        { kind: :image, filename: att.filename.to_s, mime_type: ct, data_uri: "data:#{ct};base64,#{base64}" }
      elsif ct == "application/pdf"
        { kind: :pdf, text: extract_pdf(att), filename: att.filename.to_s }
      elsif ct.start_with?("text/")
        { kind: :text, text: extract_text(att), filename: att.filename.to_s }
      end # 未対応はnilでスキップ
    end

    def extract_pdf(att)
      reader = PDF::Reader.new(StringIO.new(att.download))
      buf = +""
      reader.pages.first(MAX_PAGES).each do |page|
        buf << page.text.to_s << "\n\n"
        break if buf.length >= MAX_CHARS
      end
      truncate(buf)
    rescue => e
      Rails.logger.warn(pdf_extract_error: e.message, blob_id: att.blob_id)
      "(PDFのテキスト抽出に失敗しました)"
    end

    def extract_text(att)
      truncate(att.download.to_s)
    rescue => e
      Rails.logger.warn(text_extract_error: e.message, blob_id: att.blob_id)
      "(テキストの抽出に失敗しました)"
    end

    def truncate(s)
      s.length <= MAX_CHARS ? s : s[0...MAX_CHARS] + "\n...[truncated]"
    end
  end
end
