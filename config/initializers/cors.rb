# Restrict cross-origin browser requests. Server-to-server requests from
# Kit's plugin infrastructure don't carry an Origin header and are unaffected.
# This is defense-in-depth against malicious browser-originated calls.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "https://app.kit.com",
      "https://kit.com",
      "https://creatornetwork.kit.com",
      /\Ahttps:\/\/.*\.up\.railway\.app\z/,
      /\Ahttp:\/\/localhost(:\d+)?\z/ # for local development
    )

    resource "*",
      headers: :any,
      methods: [ :get, :post, :options, :head ]
  end
end
