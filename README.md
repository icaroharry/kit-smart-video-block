# Smart Video Block — Kit App Store Plugin

An AI-powered content block plugin for [Kit](https://kit.com) (formerly ConvertKit). Paste a YouTube URL in Kit's email editor and get a newsletter-ready email section back: thumbnail, AI-generated takeaways, and a CTA button. No extra config.

**Live demo:** https://kit.icaro.io/demo

## What it does

Creators using Kit often repurpose their YouTube videos into newsletter content. Today, this means manually writing a summary, grabbing the thumbnail, and formatting a CTA. This plugin automates the whole thing.

**In Kit's email editor:**

1. Add the Smart Video Block
2. Paste a YouTube URL
3. Get a polished email block — thumbnail, AI-generated takeaways, and a CTA button

That's it. The AI picks the best framing for the video and writes the copy. No tone or format settings — the plugin keeps the surface as small as possible.

## Why this exists

I built this as part of my application for the **Senior Software Engineer, Creator Growth and Monetization** role at Kit, on the Network Squad.

It's also an example of how I work: I used **Claude Code** to research Kit's developer platform, design the architecture, and build, debug, and ship the entire app — front-end, back-end, deployment, custom domain, and security hardening — in a single focused session. The full conversation is reproducible from the commit history.

The Smart Video Block solves a real workflow for Kit creators (turn YouTube videos into newsletter blocks), but more importantly it shows how I get up to speed on an unfamiliar platform fast and ship working software end to end. Along the way I found and reported real bugs in Kit's plugin API (radioGroup type returning 422, generic error messages), which is part of the story too.

## Tech stack

- **Ruby 3.3** + **Rails 8** — matches Kit's actual backend stack
- **Hotwire** (Turbo + Stimulus) — for the async demo page
- **Tailwind CSS v4** — Kit's frontend framework
- **Google Gemini** (`gemini-2.5-flash` with fallback to `gemini-2.5-flash-lite`) — direct YouTube video understanding via `fileData.fileUri`
- **No YouTube API key needed** — Gemini fetches the video directly, no transcript scraping

## Architecture

```
kit-plugin/
├── app/
│   ├── controllers/
│   │   ├── api/plugin_controller.rb      # POST /api/plugin/render (Kit spec)
│   │   ├── demo_controller.rb            # POST /demo/generate (Turbo Stream)
│   │   ├── pages_controller.rb           # Landing + demo pages
│   │   └── application_controller.rb     # client_ip helper for rate limiting
│   ├── services/
│   │   ├── video_summary_service.rb      # Orchestrator
│   │   ├── gemini_service.rb             # Gemini REST API client (with model fallback)
│   │   ├── email_html_builder.rb         # Email-safe HTML generation
│   │   └── youtube/
│   │       ├── metadata_service.rb       # oEmbed metadata
│   │       └── url_parser.rb             # URL → video ID
│   ├── views/
│   │   ├── pages/                        # Landing + demo
│   │   └── demo/                         # Turbo Stream partials
│   └── javascript/controllers/           # Stimulus controllers
├── config/
│   └── initializers/cors.rb              # CORS allowlist (kit.com, *.icaro.io, etc)
└── public/
    └── plugin-settings.json              # Kit plugin settings schema
```

## Kit Plugin Endpoint

`POST /api/plugin/render`

**Request:**
```json
{
  "settings": {
    "youtube_url": "https://youtube.com/watch?v=..."
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

**Errors:**
- `422` — missing or invalid YouTube URL
- `429` — rate limit exceeded (1 request per 10s per IP)
- `500` — Gemini or YouTube fetch failed

All HTML returned follows Kit's email-safe constraints: inline styles only, no scripts, no iframes, no forms, no external CSS. Links use `target="_blank" rel="noopener noreferrer"`.

## Plugin Settings Schema

See [`public/plugin-settings.json`](public/plugin-settings.json) for the exact JSON to paste into Kit's developer portal when registering the plugin.

## Production hardening

- **Rate limit**: 1 request per 10 seconds per IP, keyed by `CF-Connecting-IP` to see past Railway's Cloudflare proxy
- **CORS**: only `kit.com`, `app.kit.com`, `creatornetwork.kit.com`, `*.icaro.io`, `*.up.railway.app`, and localhost
- **API key safety**: Gemini key only in env vars, never in code or git history
- **Force SSL** in production (`config.force_ssl = true`)

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
curl -X POST https://kit.icaro.io/api/plugin/render \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    }
  }'
```

## Deployment

Works on any Rails-compatible host. Required:

1. Ruby 3.3+
2. `GEMINI_API_KEY` environment variable
3. `RAILS_MASTER_KEY` environment variable (for credentials)
4. HTTPS endpoint reachable by Kit

This app is deployed on **Railway** with the custom domain `kit.icaro.io`. Railway auto-detects Rails, sets `PORT`, handles SSL via Let's Encrypt.

## Integrating with Kit

Once deployed to a public HTTPS URL:

1. Sign in to your Kit account at https://app.kit.com
2. Go to **Apps → Build → + New app**
3. Inside the app, **Plugins tab → + New plugin**, type **Content Block**
4. Configure:
   - **Request URL:** `https://kit.icaro.io/api/plugin/render`
   - **Settings JSON:** contents of `public/plugin-settings.json`
5. Test in your own Kit account (plugin defaults to inactive — only the developer sees it)
6. Submit for App Store review when ready

## License

MIT
