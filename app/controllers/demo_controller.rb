class DemoController < ApplicationController
  # Rate limit: 1 request per 10 seconds per IP.
  rate_limit to: 1, within: 10.seconds, with: -> { render_rate_limit }

  def generate
    youtube_url = params[:youtube_url]

    if youtube_url.blank?
      return render turbo_stream: turbo_stream.replace(
        "email-preview",
        partial: "demo/error",
        locals: { message: "Please enter a YouTube URL" }
      )
    end

    result = VideoSummaryService.call(youtube_url: youtube_url)

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

  private

  def render_rate_limit
    render turbo_stream: turbo_stream.replace(
      "email-preview",
      partial: "demo/error",
      locals: { message: "Rate limit exceeded. Please wait 10 seconds between requests." }
    )
  end
end
