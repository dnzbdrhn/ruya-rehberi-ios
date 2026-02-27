# DreamOracle Backend Proxy

This server keeps the OpenAI API key off the iOS client.

## Requirements

- Node.js 18+
- npm

## Setup

1. Install dependencies:
```bash
npm install
```
2. Create env file:
```bash
cp .env.example .env
```
3. Set environment variables in `.env` (or export them):
```bash
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="your-gemini-server-key"
export PORT=3000
export REQUIRE_AUTH=true
```
Optional:
```bash
export BACKEND_AUTH_TOKEN="your-debug-token"
export RATE_LIMIT_WINDOW_MS=60000
export RATE_LIMIT_MAX=30
export IMAGE_RATE_LIMIT_WINDOW_MS=60000
export IMAGE_RATE_LIMIT_MAX=30
```
4. Run:
```bash
npm run dev
```

Startup validation:
- Server exits immediately if `OPENAI_API_KEY` is missing.
- Server exits immediately if `REQUIRE_AUTH=true` and `BACKEND_AUTH_TOKEN` is missing.
- `GEMINI_API_KEY` is optional at startup, but required to use `/v1/dream/image`.

## Endpoints

- `POST /v1/dream/interpret`
  - Accepts both:
    - New format: `{ "model": "gpt-4.1-mini", "input": [...] }`
    - Legacy format: `{ "text": "..." }`
  - Legacy requests are normalized internally to OpenAI Responses `input` format.
- `POST /v1/dream/transcribe`
  - Accepts base64 audio payload and forwards to OpenAI transcription API.
- `POST /v1/dream/image`
  - Proxies dream image generation to Gemini.
  - Request JSON:
    - `prompt` (required string)
    - `size` (optional: `1024x1024` or `768x768`)
    - `seed` (optional number)
    - `style` (optional string)
  - Response JSON:
    - `{ "image_base64": "<base64png>" }`
- `GET /health`
  - Returns `200 {"ok":true}` without calling OpenAI.

## Auth Behavior

- `REQUIRE_AUTH=true` (default):
  - `/v1/*` requires either:
    - `Authorization: Bearer <token>`, or
    - `X-Backend-Token: <token>`
  - Token must match `BACKEND_AUTH_TOKEN`.
  - Missing/invalid token returns `401 {"error":"unauthorized"}`.
- `REQUIRE_AUTH=false`:
  - Token is not required.
  - If token is provided and `BACKEND_AUTH_TOKEN` is set, wrong token still returns `401`.

## Rate Limiting

- In-memory IP limiter (simple baseline).
- `RATE_LIMIT_WINDOW_MS` default: `60000`.
- `RATE_LIMIT_MAX` default:
  - `30` when `REQUIRE_AUTH=true`
  - `120` when `REQUIRE_AUTH=false`
- Image endpoint limiter:
  - `IMAGE_RATE_LIMIT_WINDOW_MS` default: same as `RATE_LIMIT_WINDOW_MS`
  - `IMAGE_RATE_LIMIT_MAX` default:
    - `30` when `REQUIRE_AUTH=true`
    - `60` when `REQUIRE_AUTH=false`

## Curl examples

Secure mode (`REQUIRE_AUTH=true`):
```bash
curl -s -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BACKEND_AUTH_TOKEN" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"test"}]}]}'
```

Legacy interpret format (expects 200):
```bash
curl -i -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -d '{"text":"I saw a moon over the sea"}'
```

New interpret format (expects 200):
```bash
curl -i -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"I saw a moon over the sea"}]}]}'
```

Test mode (`REQUIRE_AUTH=false`, tokenless):
```bash
curl -s -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"test"}]}]}'
```

Gemini image example:
```bash
curl -i -X POST "http://127.0.0.1:3000/v1/dream/image" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"moonlit sea, calm symbols","size":"1024x1024"}'
```

Unauthorized example:
```bash
curl -i -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer wrong-token" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"test"}]}]}'
```

## Security notes

- `OPENAI_API_KEY` must be set only on server environment.
- `GEMINI_API_KEY` must be set only on server environment.
- Do not commit real secrets.
- In-memory rate limiter in `index.js` is a stub; replace with durable infra in production.
- Safe request logs include only method/path/status/latency (no request bodies).
