require "net/http"
require "json"
require "rexml/document"

module YouTube
  class TranscriptService
    # Public InnerTube API key used by YouTube's iOS client. Safe to use for public data.
    INNERTUBE_API_KEY = "AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc".freeze
    INNERTUBE_URL = "https://www.youtube.com/youtubei/v1/player".freeze

    def self.call(video_id)
      new(video_id).call
    end

    def initialize(video_id)
      @video_id = video_id
    end

    def call
      captions_url = fetch_captions_url_via_innertube || fetch_captions_url_via_watch_page

      raise "No captions available for this video" unless captions_url

      transcript_xml = fetch_transcript(captions_url)
      parse_transcript(transcript_xml)
    end

    private

    # Primary: InnerTube API (same endpoint YouTube mobile apps use, works on datacenter IPs)
    def fetch_captions_url_via_innertube
      uri = URI("#{INNERTUBE_URL}?key=#{INNERTUBE_API_KEY}")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-YouTube-Client-Name"] = "5"   # iOS client
      request["X-YouTube-Client-Version"] = "19.09.3"

      request.body = {
        videoId: @video_id,
        context: {
          client: {
            clientName: "IOS",
            clientVersion: "19.09.3",
            deviceMake: "Apple",
            deviceModel: "iPhone16,2",
            hl: "en",
            gl: "US"
          }
        }
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10) do |http|
        http.request(request)
      end

      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      tracks = data.dig("captions", "playerCaptionsTracklistRenderer", "captionTracks")
      return nil if tracks.nil? || tracks.empty?

      pick_track(tracks)
    rescue JSON::ParserError, StandardError => e
      Rails.logger.warn("InnerTube transcript fetch failed: #{e.message}")
      nil
    end

    # Fallback: parse the watch page HTML (works reliably locally, less so on datacenter IPs)
    def fetch_captions_url_via_watch_page
      uri = URI("https://www.youtube.com/watch?v=#{@video_id}")
      request = Net::HTTP::Get.new(uri)
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10) do |http|
        http.request(request)
      end

      return nil unless response.is_a?(Net::HTTPSuccess)

      extract_captions_url_from_html(response.body)
    rescue StandardError => e
      Rails.logger.warn("Watch page transcript fetch failed: #{e.message}")
      nil
    end

    def extract_captions_url_from_html(html)
      tracks_match = html.match(/"captionTracks":\s*(\[.*?\])/)
      return nil unless tracks_match

      tracks = JSON.parse(tracks_match[1])
      return nil if tracks.empty?

      pick_track(tracks)
    rescue JSON::ParserError
      nil
    end

    def pick_track(tracks)
      english = tracks.find { |t| t["languageCode"]&.start_with?("en") }
      track = english || tracks.first
      track["baseUrl"]
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
