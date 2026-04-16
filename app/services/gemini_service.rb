class GeminiService
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models".freeze
  MODELS = %w[gemini-2.5-flash gemini-2.5-flash-lite].freeze

  def self.call(transcript:, tone:, format:, title: nil)
    new(transcript:, tone:, format:, title:).call
  end

  def initialize(transcript:, tone:, format:, title: nil)
    @transcript = transcript
    @tone = tone
    @format = format
    @title = title
  end

  def call
    last_error = nil

    MODELS.each do |model|
      response = HTTParty.post(
        "#{BASE_URL}/#{model}:generateContent?key=#{api_key}",
        headers: { "Content-Type" => "application/json" },
        body: {
          contents: [ { parts: [ { text: build_prompt } ] } ],
          generationConfig: { temperature: 0.7, maxOutputTokens: 1024 }
        }.to_json,
        timeout: 30
      )

      if response.success?
        data = response.parsed_response
        candidates = data.dig("candidates")
        next if candidates.nil? || candidates.empty?

        text = candidates.first.dig("content", "parts", 0, "text")&.strip
        return text if text.present?
      end

      last_error = "#{model}: #{response.code} - #{response.parsed_response&.dig("error", "message") || response.body}"
      Rails.logger.warn("GeminiService: #{last_error}")
    end

    raise "Gemini API unavailable: #{last_error}"
  end

  private

  def api_key
    ENV.fetch("GEMINI_API_KEY") { raise "GEMINI_API_KEY environment variable is not set" }
  end

  def build_prompt
    <<~PROMPT
      You are extracting email newsletter content from a YouTube video transcript.

      Video title: #{@title}
      Transcript (first 8000 chars): #{@transcript[0..8000]}

      Task: #{format_instructions}

      Tone: #{tone_instructions}

      STRICT OUTPUT RULES:
      - Output ONLY the requested content. Nothing else.
      - NO greetings ("Hey everyone", "Hi friends", "What's up")
      - NO intros ("Got a new video out", "Here are the main points", "In this video")
      - NO meta-commentary ("I hope this helps", "Let me know what you think")
      - NO markdown, NO bullet characters (-, *, •), NO numbering (1., 2., 3.)
      - NO quotes wrapping the output
      - Write in second person ("you") speaking directly to the reader
      - Reference specific, concrete points from the video, not generic advice
      - Output the content and stop. Do not explain, introduce, or close.
    PROMPT
  end

  def format_instructions
    case @format
    when "takeaways"
      "Extract exactly 3 key takeaways from the video. Each takeaway is ONE self-contained sentence (12-25 words). Output 3 lines separated by single newlines. Nothing else."
    when "teaser"
      "Write a 2-sentence hook (max 40 words total) that creates curiosity about the video without revealing the main points. Output the 2 sentences and nothing else."
    when "summary"
      "Write a 3-4 sentence summary (max 80 words total) covering the video's main points. Output the summary as a single paragraph and nothing else."
    else
      "Extract exactly 3 key takeaways from the video, one per line."
    end
  end

  def tone_instructions
    case @tone
    when "casual"
      "Conversational, warm, first-name-basis. Contractions allowed. No jargon."
    when "professional"
      "Clear, polished, confident. No slang. No contractions unless natural."
    when "storytelling"
      "Narrative, vivid, builds intrigue. Uses specific details and sensory language."
    else
      "Clear and engaging."
    end
  end
end
