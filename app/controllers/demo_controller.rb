class DemoController < ApplicationController
  def generate
    youtube_url = params[:youtube_url]
    tone = params[:tone] || "casual"
    format_type = params[:format] || "takeaways"
    cta_text = params[:cta_text].presence || "Watch the full video"

    if youtube_url.blank?
      return render turbo_stream: turbo_stream.replace(
        "email-preview",
        partial: "demo/error",
        locals: { message: "Please enter a YouTube URL" }
      )
    end

    result = VideoSummaryService.call(
      youtube_url: youtube_url,
      tone: tone,
      format: format_type,
      cta_text: cta_text
    )

    render turbo_stream: turbo_stream.replace(
      "email-preview",
      partial: "demo/preview",
      locals: { html: result[:html], metadata: result[:metadata] }
    )
  rescue => e
    render turbo_stream: turbo_stream.replace(
      "email-preview",
      partial: "demo/error",
      locals: { message: e.message }
    )
  end
end
