class Ai::AttachmentSummarizer
  SYS = <<~SYS
    あなたはドキュメント要約アシスタントです。入力のPDFテキストや画像を読み、重要な要点を日本語で簡潔にまとめます。
    出力要件: 見出し→箇条書き→次のアクションの順で。コード/数式/表は簡略に言語化。事実に自信がない場合は推測しない。
  SYS

  def initialize(conversation:, stream_key:)
    @conversation = conversation
    @stream_key = stream_key
  end

  def call!(attachments_info, model: nil)
    model ||= @conversation.model.presence || "gemini-2.5-flash"

    parts = []
    attachments_info.each do |a|
      case a[:kind]
      when :image
        parts << { text: "画像: #{a[:filename]} の要点を抽出してください。" }
        mime, b64 = a[:data_uri].to_s.match(%r{\Adata:(.*?);base64,(.*)\z}m)&.captures
        parts << { inline_data: { mime_type: mime || a[:mime_type], data: b64 } } if b64
      when :pdf, :text
        label = a[:kind] == :pdf ? "PDF" : "テキスト"
        parts << { text: "#{label}: #{a[:filename]}\n---\n#{a[:text]}" }
      end
    end

    messages = [
      { role: "system", content: SYS },
      { role: "user", content: parts }
    ]

    # 既存のStreamingChatへ委譲——ストリーミング配信・停止・保存の仕組みはそのまま再利用
    Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: @stream_key)
                     .call!(messages, model: model, **@conversation.params_for_gemini.except(:model))
  end
end
