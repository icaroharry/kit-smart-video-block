module Api
  class PluginController < ApplicationController
    skip_forgery_protection

    # Rate limit: 1 request per 10 seconds per IP.
    # Uses client_ip (CF-Connecting-IP / X-Forwarded-For) to see past Railway's proxies.
    rate_limit to: 1, within: 10.seconds, by: -> { client_ip }, with: -> { render_rate_limit }

    def render_block
      settings = params[:settings] || {}

      youtube_url = settings[:youtube_url]
      tone = settings[:tone] || "casual"
      format_type = settings[:format] || "takeaways"
      cta_text = settings[:cta_text] || "Watch the full video"

      if youtube_url.blank?
        return render json: { code: 422, errors: [ "YouTube URL is required" ] }, status: :unprocessable_entity
      end

      result = VideoSummaryService.call(
        youtube_url: youtube_url,
        tone: tone,
        format: format_type,
        cta_text: cta_text
      )

      render json: { code: 200, html: result[:html] }
    rescue => e
      render json: { code: 500, errors: [ e.message ] }, status: :internal_server_error
    end

    private

    def render_rate_limit
      render json: {
        code: 429,
        errors: [ "Rate limit exceeded. Please wait 10 seconds between requests." ]
      }, status: :too_many_requests
    end
  end
end
