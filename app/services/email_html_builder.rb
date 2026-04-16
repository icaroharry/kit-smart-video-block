class EmailHtmlBuilder
  def self.call(metadata:, content:, cta_text:, format:)
    new(metadata:, content:, cta_text:, format:).call
  end

  def initialize(metadata:, content:, cta_text:, format:)
    @metadata = metadata
    @content = content
    @cta_text = cta_text
    @format = format
  end

  def call
    <<~HTML
      <div style="max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
        #{thumbnail_section}
        #{title_section}
        #{content_section}
        #{cta_section}
      </div>
    HTML
  end

  private

  def thumbnail_section
    <<~HTML
      <a href="#{@metadata[:video_url]}" target="_blank" rel="noopener noreferrer" style="display: block; text-decoration: none; position: relative;">
        <div style="position: relative; border-radius: 8px; overflow: hidden;">
          <img src="#{@metadata[:thumbnail_url]}" alt="#{escape(@metadata[:title])}" style="width: 100%; height: auto; display: block;" />
          <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 60px; height: 60px; background: rgba(0,0,0,0.7); border-radius: 50%; display: flex; align-items: center; justify-content: center;">
            <div style="width: 0; height: 0; border-style: solid; border-width: 10px 0 10px 18px; border-color: transparent transparent transparent #ffffff; margin-left: 4px;"></div>
          </div>
        </div>
      </a>
    HTML
  end

  def title_section
    <<~HTML
      <h2 style="font-size: 20px; font-weight: 700; color: #111827; margin: 16px 0 4px; line-height: 1.3;">
        #{escape(@metadata[:title])}
      </h2>
      <p style="font-size: 13px; color: #6b7280; margin: 0 0 16px;">
        by #{escape(@metadata[:author])}
      </p>
    HTML
  end

  def content_section
    case @format
    when "takeaways"
      takeaways_html
    else
      paragraph_html
    end
  end

  def takeaways_html
    items = @content.split("\n").map(&:strip).reject(&:empty?)

    list_items = items.map do |item|
      clean = item.sub(/^\d+[\.\)]\s*/, "").sub(/^[-*]\s*/, "")
      <<~HTML
        <tr>
          <td style="vertical-align: top; padding: 0 8px 12px 0; color: #6366f1; font-size: 18px; font-weight: bold; line-height: 1.5;">&#10003;</td>
          <td style="vertical-align: top; padding: 0 0 12px; font-size: 15px; color: #374151; line-height: 1.5;">#{escape(clean)}</td>
        </tr>
      HTML
    end.join

    <<~HTML
      <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 8px 0 16px;">
        #{list_items}
      </table>
    HTML
  end

  def paragraph_html
    <<~HTML
      <p style="font-size: 15px; color: #374151; line-height: 1.6; margin: 8px 0 16px;">
        #{escape(@content)}
      </p>
    HTML
  end

  def cta_section
    <<~HTML
      <div style="text-align: center; margin: 8px 0 16px;">
        <a href="#{@metadata[:video_url]}" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #6366f1; color: #ffffff; font-size: 15px; font-weight: 600; text-decoration: none; padding: 12px 28px; border-radius: 6px;">
          #{escape(@cta_text)} &#8594;
        </a>
      </div>
    HTML
  end

  def escape(text)
    ERB::Util.html_escape(text.to_s)
  end
end
