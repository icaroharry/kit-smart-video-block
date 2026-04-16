module YouTube
  class MetadataService
    OEMBED_URL = "https://www.youtube.com/oembed".freeze

    def self.call(video_id)
      new(video_id).call
    end

    def initialize(video_id)
      @video_id = video_id
    end

    def call
      response = HTTParty.get(OEMBED_URL, query: {
        url: "https://www.youtube.com/watch?v=#{@video_id}",
        format: "json"
      })

      raise "YouTube video not found" unless response.success?

      data = response.parsed_response

      {
        title: data["title"],
        author: data["author_name"],
        author_url: data["author_url"],
        thumbnail_url: "https://i.ytimg.com/vi/#{@video_id}/hqdefault.jpg",
        video_url: "https://www.youtube.com/watch?v=#{@video_id}",
        video_id: @video_id
      }
    end
  end
end
