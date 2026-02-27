const express = require("express");
const helmet = require("helmet");
const OpenAI = require("openai");
const { toFile } = require("openai/uploads");

const PORT = Number(process.env.PORT || 3000);
const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || "").trim();
const NODE_ENV = (process.env.NODE_ENV || "development").trim().toLowerCase();
const IS_PRODUCTION = NODE_ENV === "production";
const BACKEND_AUTH_TOKEN = (process.env.BACKEND_AUTH_TOKEN || "").trim();
const DEV_DEFAULT_AUTH_TOKEN = "dev-local-token";
const JSON_BODY_LIMIT = "15mb";

const RATE_WINDOW_MS = 60_000;
const RATE_MAX_PER_WINDOW = 120;
const rateState = new Map();

validateEnvironment();

const openai = new OpenAI({ apiKey: OPENAI_API_KEY });
const app = express();
app.disable("x-powered-by");
app.use(helmet());
app.use(express.json({ limit: JSON_BODY_LIMIT }));

app.use((req, res, next) => {
  const startedAt = process.hrtime.bigint();
  res.on("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
    console.log(
      `[request] ${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs.toFixed(1)}ms`
    );
  });
  next();
});

// Mobile app requests do not require CORS. Keep browser CORS disabled by default.

app.use((req, res, next) => {
  const ip = req.ip || req.socket.remoteAddress || "unknown";
  const now = Date.now();
  const state = rateState.get(ip) || { count: 0, resetAt: now + RATE_WINDOW_MS };

  if (now > state.resetAt) {
    state.count = 0;
    state.resetAt = now + RATE_WINDOW_MS;
  }

  state.count += 1;
  rateState.set(ip, state);

  // Minimal in-memory rate limiter stub; replace with Redis/edge limiter in production.
  if (state.count > RATE_MAX_PER_WINDOW) {
    return res.status(429).json({ error: { message: "Too many requests." } });
  }

  next();
});

app.use("/v1", (req, res, next) => {
  const bearerToken = parseBearerToken(req.get("Authorization"));

  if (IS_PRODUCTION) {
    if (bearerToken !== BACKEND_AUTH_TOKEN) {
      return unauthorized(res);
    }
    return next();
  }

  // Development mode:
  // - No token: allow (local convenience)
  // - Token provided: must match BACKEND_AUTH_TOKEN or DEV_DEFAULT_AUTH_TOKEN
  if (!bearerToken) {
    return next();
  }

  const accepted = new Set([DEV_DEFAULT_AUTH_TOKEN]);
  if (BACKEND_AUTH_TOKEN) {
    accepted.add(BACKEND_AUTH_TOKEN);
  }
  if (!accepted.has(bearerToken)) {
    return unauthorized(res);
  }

  next();
});

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/v1/dream/interpret", async (req, res) => {
  try {
    const { model = "gpt-4.1-mini", input, max_output_tokens } = req.body || {};
    if (!Array.isArray(input) || input.length === 0) {
      return res.status(400).json({ error: { message: "input array is required." } });
    }

    const response = await openai.responses.create({
      model,
      input,
      max_output_tokens
    });

    return res.json({
      output_text: response.output_text ?? null,
      output: response.output ?? []
    });
  } catch (error) {
    return handleError(res, error);
  }
});

app.post("/v1/dream/transcribe", async (req, res) => {
  try {
    const {
      audioBase64,
      filename = "audio.m4a",
      mimeType = "audio/m4a",
      model = "gpt-4o-mini-transcribe",
      language = "tr"
    } = req.body || {};

    if (!audioBase64 || typeof audioBase64 !== "string") {
      return res.status(400).json({ error: { message: "audioBase64 is required." } });
    }

    const audioBuffer = Buffer.from(audioBase64, "base64");
    if (!audioBuffer.length) {
      return res.status(400).json({ error: { message: "Invalid audio payload." } });
    }

    const file = await toFile(audioBuffer, filename, { type: mimeType });

    const transcription = await openai.audio.transcriptions.create({
      file,
      model,
      language
    });

    return res.json({ text: transcription.text ?? "" });
  } catch (error) {
    return handleError(res, error);
  }
});

app.listen(PORT, () => {
  console.log(`[server] listening on http://localhost:${PORT}`);
});

function validateEnvironment() {
  if (!OPENAI_API_KEY) {
    console.error("[startup] Missing OPENAI_API_KEY. Set it in server environment.");
    process.exit(1);
  }

  if (IS_PRODUCTION && !BACKEND_AUTH_TOKEN) {
    console.error("[startup] Missing BACKEND_AUTH_TOKEN in production mode.");
    process.exit(1);
  }
}

function parseBearerToken(value) {
  if (!value) return "";
  const [scheme, token] = value.split(" ");
  if (scheme?.toLowerCase() !== "bearer") return "";
  return token || "";
}

function unauthorized(res) {
  return res.status(401).json({ error: "unauthorized" });
}

function handleError(res, error) {
  const status =
    Number(error?.status) ||
    Number(error?.statusCode) ||
    Number(error?.response?.status) ||
    500;
  const message =
    error?.message ||
    error?.error?.message ||
    "Unexpected server error.";

  return res.status(status).json({ error: { message } });
}
