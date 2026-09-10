module MarkdownHelper
  ALLOWED_TAGS = %w[p br a code pre h1 h2 h3 h4 h5 h6 ul ol li strong em blockquote table thead tbody tr th td img hr]
  ALLOWED_ATTRS = %w[href rel target src alt]

  def md_to_html(text)
    html = Commonmarker.to_html(text.to_s, options: {
      parse: { smart: true }, render: { hardbreaks: false, unsafe: false },
      extension: { table: true, strikethrough: true, autolink: true, tasklist: true, tagfilter: true }
    })
    sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end
end
