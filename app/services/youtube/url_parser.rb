module YouTube
  class UrlParser
    PATTERNS = [
      /(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})/,
      /(?:youtu\.be\/)([a-zA-Z0-9_-]{11})/,
      /(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /(?:youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/
    ].freeze

    def self.extract_video_id(url)
      return nil if url.nil? || url.strip.empty?

      PATTERNS.each do |pattern|
        match = url.match(pattern)
        return match[1] if match
      end

      nil
    end
  end
end
