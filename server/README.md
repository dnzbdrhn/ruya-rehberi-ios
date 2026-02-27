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
2. Set environment variables:
```bash
export OPENAI_API_KEY="sk-..."
export PORT=3000
export NODE_ENV=development
```
Optional:
```bash
export BACKEND_AUTH_TOKEN="your-debug-token"
```
3. Run:
```bash
npm run dev
```

Startup validation:
- Server exits immediately if `OPENAI_API_KEY` is missing.
- In `NODE_ENV=production`, server exits if `BACKEND_AUTH_TOKEN` is missing.

## Endpoints

- `POST /v1/dream/interpret`
  - Forwards structured interpretation request to OpenAI Responses API.
- `POST /v1/dream/transcribe`
  - Accepts base64 audio payload and forwards to OpenAI transcription API.

## iOS Debug config

- Set `BACKEND_BASE_URL` in `DreamOracle/Info.plist` (for simulator local run, `http://127.0.0.1:3000`).
- Optional debug auth: define `BACKEND_AUTH_TOKEN` as Xcode Run environment variable.

## Auth behavior by environment

- Production (`NODE_ENV=production`):
  - All `/v1/*` routes require `Authorization: Bearer <BACKEND_AUTH_TOKEN>`.
  - Missing or invalid token returns `401` with `{ "error": "unauthorized" }`.
- Development (`NODE_ENV=development`):
  - Missing Authorization header is allowed for local convenience.
  - If Authorization header is provided, accepted values are:
    - `BACKEND_AUTH_TOKEN` (if set), or
    - default dev token `dev-local-token`.
  - Invalid token returns `401` with `{ "error": "unauthorized" }`.

## Curl examples

Production-style (authorized):
```bash
curl -s -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BACKEND_AUTH_TOKEN" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"test"}]}]}'
```

Unauthorized example:
```bash
curl -i -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4.1-mini","input":[]}'
```

## Security notes

- `OPENAI_API_KEY` must be set only on server environment.
- Do not commit real secrets.
- In-memory rate limiter in `index.js` is a stub; replace with durable infra in production.
- Safe request logs include only method/path/status/latency (no request bodies).
