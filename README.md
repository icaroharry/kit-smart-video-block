# Smart Video Block — Kit App Store Plugin

An AI-powered content block plugin for [Kit](https://kit.com) (formerly ConvertKit). Paste a YouTube URL in Kit's email editor and generate a newsletter-ready email section with thumbnail, AI-generated takeaways, and a CTA button.

Built as a prototype to demonstrate a Kit App Store plugin using Kit's actual backend stack (Ruby on Rails, Hotwire, Tailwind) + Google Gemini for AI content generation.

## What it does

Creators using Kit often repurpose their YouTube videos into newsletter content. Today, this means manually writing a summary, grabbing the thumbnail, and formatting a CTA. This plugin automates the whole thing.

**In Kit's email editor:**

1. Add the Smart Video Block
2. Paste a YouTube URL
3. Pick a tone (casual, professional, storytelling) and format (takeaways, teaser, summary)
4. Get a rendered email block with thumbnail, AI-generated copy, and CTA button

## Tech stack

- **Ruby 3.3** + **Rails 8** — matches Kit's backend stack
- **Hotwire** (Turbo + Stimulus) — for the async demo page
- **Tailwind CSS v4** — Kit's frontend framework
- **Google Gemini** (`gemini-2.5-flash` with fallback to `gemini-2.5-flash-lite`) — AI content generation
- **YouTube oEmbed + direct transcript extraction** — no YouTube API key required

## Architecture

```
kit-plugin/
├── app/
│   ├── controllers/
│   │   ├── api/plugin_controller.rb      # POST /api/plugin/render (Kit spec)
│   │   ├── demo_controller.rb            # POST /demo/generate (Turbo Stream)
│   │   └── pages_controller.rb           # Landing + demo pages
│   ├── services/
│   │   ├── video_summary_service.rb      # Orchestrator
│   │   ├── gemini_service.rb             # Gemini REST API client
│   │   ├── email_html_builder.rb         # Email-safe HTML generation
│   │   └── youtube/
│   │       ├── metadata_service.rb       # oEmbed metadata
│   │       ├── transcript_service.rb     # Direct transcript extraction
│   │       └── url_parser.rb             # URL → video ID
│   ├── views/
│   │   ├── pages/                        # Landing + demo
│   │   └── demo/                         # Turbo Stream partials
│   └── javascript/controllers/           # Stimulus controllers
└── public/
    └── plugin-settings.json              # Kit plugin settings schema
```

## Kit Plugin Endpoint

`POST /api/plugin/render`

**Request:**
```json
{
  "settings": {
    "youtube_url": "https://youtube.com/watch?v=...",
    "tone": "casual",
    "format": "takeaways",
    "cta_text": "Watch the full video"
  }
}
```

**Response:**
```json
{
  "code": 200,
  "html": "<div style='...'>...</div>"
}
```

**Error:**
```json
{
  "code": 422,
  "errors": ["YouTube URL is required"]
}
```

All HTML returned follows Kit's email-safe constraints: inline styles only, no scripts, no iframes, no forms, no external CSS. Links use `target="_blank" rel="noopener noreferrer"`.

## Plugin Settings Schema

See [`public/plugin-settings.json`](public/plugin-settings.json) for the exact JSON to paste into Kit's developer portal when registering the plugin.

## Local development

```bash
# 1. Ruby 3.3 (via mise, rbenv, or asdf)
mise install ruby@3.3

# 2. Install gems
bundle install

# 3. Set your Gemini API key
echo "GEMINI_API_KEY=your_key_here" > .env

# 4. Run the server
bin/rails server -p 3333
```

Open:
- `http://localhost:3333` — landing page
- `http://localhost:3333/demo` — interactive demo

Get a free Gemini API key at [aistudio.google.com](https://aistudio.google.com).

## Testing the plugin endpoint

```bash
curl -X POST http://localhost:3333/api/plugin/render \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "tone": "casual",
      "format": "takeaways",
      "cta_text": "Watch now"
    }
  }'
```

## Deployment

Works on any Rails-compatible host. The only requirements:

1. Ruby 3.3+
2. `GEMINI_API_KEY` environment variable
3. HTTPS endpoint reachable by Kit

### Railway setup

1. Push this repo to GitHub
2. Create a new Railway project → Deploy from GitHub repo
3. Add environment variable: `GEMINI_API_KEY`
4. Railway auto-detects Rails and deploys

## Integrating with Kit

Once deployed to a public HTTPS URL:

1. Register a developer account at [developers.kit.com](https://developers.kit.com)
2. Create a new App
3. Add a **Content Block Plugin** with:
   - **HTML URL:** `https://your-domain.com/api/plugin/render`
   - **Settings schema:** contents of `public/plugin-settings.json`
4. Test in your own Kit account (developer mode)
5. Submit for App Store review

## Why this exists

Built as a portfolio project targeting Kit's Senior Software Engineer role on the Network Squad. Chose this specific plugin because:

- **AI is a gap** — Kit has zero AI-powered apps in their store yet
- **YouTube is Kit's core audience** — many Kit creators are YouTubers
- **Content Block plugins are the most visible** plugin type (they render inline in the editor)
- **Uses Kit's actual stack** — Rails 8 + Hotwire + Tailwind, nothing foreign

## License

MIT
