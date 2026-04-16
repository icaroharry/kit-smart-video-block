require "net/http"
require "json"
require "rexml/document"

module YouTube
  class TranscriptService
    def self.call(video_id)
      new(video_id).call
    end

    def initialize(video_id)
      @video_id = video_id
    end

    def call
      page_html = fetch_watch_page
      captions_url = extract_captions_url(page_html)

      raise "No captions available for this video" unless captions_url

      transcript_xml = fetch_transcript(captions_url)
      parse_transcript(transcript_xml)
    end

    private

    def fetch_watch_page
      uri = URI("https://www.youtube.com/watch?v=#{@video_id}")
      request = Net::HTTP::Get.new(uri)
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      raise "Failed to fetch YouTube page" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def extract_captions_url(html)
      match = html.match(/"captions":\s*(\{.*?"playerCaptionsTracklistRenderer".*?\})\s*,\s*"videoDetails"/)
      return nil unless match

      captions_json = match[1]

      # Fix potential JSON issues by finding the proper closing
      # Look for the captionTracks array
      tracks_match = captions_json.match(/"captionTracks":\s*(\[.*?\])/)
      return nil unless tracks_match

      tracks = JSON.parse(tracks_match[1])
      return nil if tracks.empty?

      # Prefer English, fall back to first available
      english_track = tracks.find { |t| t["languageCode"]&.start_with?("en") }
      track = english_track || tracks.first

      track["baseUrl"]
    rescue JSON::ParserError
      nil
    end

    def fetch_transcript(url)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      raise "Failed to fetch transcript" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def parse_transcript(xml_string)
      doc = REXML::Document.new(xml_string)
      segments = []

      doc.elements.each("transcript/text") do |element|
        text = element.text&.gsub("&amp;", "&")
          &.gsub("&#39;", "'")
          &.gsub("&quot;", '"')
          &.gsub("&lt;", "<")
          &.gsub("&gt;", ">")
          &.strip

        segments << text if text && !text.empty?
      end

      segments.join(" ")
    end
  end
end
