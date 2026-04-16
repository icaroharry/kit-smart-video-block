class VideoSummaryService
  def self.call(youtube_url:, tone: "casual", format: "takeaways", cta_text: "Watch the full video")
    new(youtube_url:, tone:, format:, cta_text:).call
  end

  def initialize(youtube_url:, tone:, format:, cta_text:)
    @youtube_url = youtube_url
    @tone = tone
    @format = format
    @cta_text = cta_text
  end

  def call
    video_id = YouTube::UrlParser.extract_video_id(@youtube_url)
    raise "Invalid YouTube URL" unless video_id

    # Canonicalize URL so Gemini always sees the watch URL format
    canonical_url = "https://www.youtube.com/watch?v=#{video_id}"

    metadata = YouTube::MetadataService.call(video_id)

    content = GeminiService.call(
      youtube_url: canonical_url,
      tone: @tone,
      format: @format,
      title: metadata[:title]
    )

    html = EmailHtmlBuilder.call(
      metadata: metadata,
      content: content,
      cta_text: @cta_text,
      format: @format
    )

    { html: html, metadata: metadata, content: content }
  end
end
