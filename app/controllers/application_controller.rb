class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Returns the real client IP, looking past Railway/Cloudflare proxies.
  # Used for rate limiting and logging.
  def client_ip
    request.headers["CF-Connecting-IP"] ||
      request.headers["X-Real-IP"] ||
      request.headers["X-Forwarded-For"]&.split(",")&.first&.strip ||
      request.remote_ip
  end
  helper_method :client_ip
end
