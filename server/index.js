require("dotenv").config();

const express = require("express");
const helmet = require("helmet");
const OpenAI = require("openai");
const { toFile } = require("openai/uploads");

const PORT = Number(process.env.PORT || 3000);
const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || "").trim();
const GEMINI_API_KEY = (process.env.GEMINI_API_KEY || "").trim();
const BACKEND_AUTH_TOKEN = (process.env.BACKEND_AUTH_TOKEN || "").trim();
const requireAuth = parseBool(process.env.REQUIRE_AUTH, true);
const RATE_LIMIT_WINDOW_MS = parsePositiveInt(process.env.RATE_LIMIT_WINDOW_MS, 60_000);
const RATE_LIMIT_MAX = parsePositiveInt(
  process.env.RATE_LIMIT_MAX,
  requireAuth ? 30 : 120
);
const IMAGE_RATE_LIMIT_WINDOW_MS = parsePositiveInt(
  process.env.IMAGE_RATE_LIMIT_WINDOW_MS,
  RATE_LIMIT_WINDOW_MS
);
const IMAGE_RATE_LIMIT_MAX = parsePositiveInt(
  process.env.IMAGE_RATE_LIMIT_MAX,
  requireAuth ? 30 : 60
);
const JSON_BODY_LIMIT = "15mb";
const GEMINI_IMAGE_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent";

const rateState = new Map();
const imageRateState = new Map();

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
  const state = rateState.get(ip) || { count: 0, resetAt: now + RATE_LIMIT_WINDOW_MS };

  if (now > state.resetAt) {
    state.count = 0;
    state.resetAt = now + RATE_LIMIT_WINDOW_MS;
  }

  state.count += 1;
  rateState.set(ip, state);

  // Minimal in-memory rate limiter stub; replace with Redis/edge limiter in production.
  if (state.count > RATE_LIMIT_MAX) {
    return res.status(429).json({ error: { message: "Too many requests." } });
  }

  next();
});

app.use("/v1", (req, res, next) => {
  const providedToken = resolveRequestToken(req);

  if (requireAuth) {
    if (!BACKEND_AUTH_TOKEN || providedToken !== BACKEND_AUTH_TOKEN) {
      return unauthorized(res);
    }
    return next();
  }

  // Auth not required: tokenless requests are allowed.
  // If a token is supplied and a shared token is configured, it must match.
  if (providedToken && BACKEND_AUTH_TOKEN && providedToken !== BACKEND_AUTH_TOKEN) {
    return unauthorized(res);
  }

  next();
});

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/v1/dream/interpret", async (req, res) => {
  try {
    const normalized = normalizeInterpretRequest(req.body || {});
    if (normalized.errorMessage) {
      return res.status(400).json({ error: { message: normalized.errorMessage } });
    }

    const response = await openai.responses.create({
      model: normalized.model,
      input: normalized.input,
      max_output_tokens: normalized.maxOutputTokens
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

app.post("/v1/dream/image", async (req, res) => {
  try {
    const ip = req.ip || req.socket.remoteAddress || "unknown";
    if (isRateLimited(imageRateState, ip, IMAGE_RATE_LIMIT_WINDOW_MS, IMAGE_RATE_LIMIT_MAX)) {
      return res.status(429).json({ error: { message: "Too many requests." } });
    }

    if (!GEMINI_API_KEY) {
      return res.status(500).json({ error: "server_misconfigured" });
    }

    const {
      prompt,
      size = "1024x1024",
      seed,
      style
    } = req.body || {};

    if (typeof prompt !== "string" || !prompt.trim()) {
      return res.status(400).json({ error: { message: "prompt is required." } });
    }

    if (prompt.length > 8_000) {
      return res.status(413).json({ error: "payload_too_large" });
    }

    const normalizedSize = normalizeImageSize(size);
    const payload = {
      contents: [{ parts: [{ text: buildGeminiImagePrompt(prompt, normalizedSize, seed, style) }] }],
      generationConfig: {
        responseModalities: ["IMAGE"]
      }
    };

    const response = await fetch(GEMINI_IMAGE_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY
      },
      body: JSON.stringify(payload)
    });

    const responseText = await response.text();
    const parsed = safeParseJSON(responseText);

    if (!response.ok) {
      const message = parsed?.error?.message || "Gemini proxy request failed.";
      return res.status(response.status || 502).json({ error: { message } });
    }

    const imageBase64 = extractGeminiImageBase64(parsed);
    if (!imageBase64) {
      return res.status(502).json({ error: { message: "Gemini image output missing." } });
    }

    return res.json({ image_base64: imageBase64.replace(/\n/g, "") });
  } catch (error) {
    return handleError(res, error);
  }
});

app.listen(PORT, () => {
  console.log(`[server] listening on http://localhost:${PORT}`);
});

function validateEnvironment() {
  console.log(
    `[startup] requireAuth=${requireAuth} openaiKeyPresent=${Boolean(OPENAI_API_KEY)} geminiKeyPresent=${Boolean(GEMINI_API_KEY)}`
  );

  if (!OPENAI_API_KEY) {
    console.error("[startup] Missing OPENAI_API_KEY. Set it in server environment.");
    process.exit(1);
  }

  if (requireAuth && !BACKEND_AUTH_TOKEN) {
    console.error("[startup] Missing BACKEND_AUTH_TOKEN while REQUIRE_AUTH=true.");
    process.exit(1);
  }
}

function isRateLimited(stateMap, key, windowMs, limit) {
  const now = Date.now();
  const state = stateMap.get(key) || { count: 0, resetAt: now + windowMs };

  if (now > state.resetAt) {
    state.count = 0;
    state.resetAt = now + windowMs;
  }

  state.count += 1;
  stateMap.set(key, state);
  return state.count > limit;
}

function normalizeImageSize(sizeValue) {
  const allowed = new Set(["1024x1024", "768x768"]);
  const value = typeof sizeValue === "string" ? sizeValue.trim() : "";
  return allowed.has(value) ? value : "1024x1024";
}

function buildGeminiImagePrompt(basePrompt, size, seed, style) {
  const styleText = typeof style === "string" && style.trim() ? style.trim() : "dreamy painterly";
  const seedText = Number.isFinite(seed) ? `Seed hint: ${seed}.` : "";

  return [
    "Create a single symbolic dream artwork.",
    `Output canvas exactly ${size}, square composition, full-bleed.`,
    `Style direction: ${styleText}.`,
    "No text, captions, logos, UI, borders, or watermark.",
    seedText,
    `Prompt: ${basePrompt.trim()}`
  ]
    .filter(Boolean)
    .join("\n");
}

function safeParseJSON(value) {
  if (!value || typeof value !== "string") return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

function extractGeminiImageBase64(payload) {
  const candidates = Array.isArray(payload?.candidates) ? payload.candidates : [];
  for (const candidate of candidates) {
    const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
    for (const part of parts) {
      const inline = part?.inlineData?.data;
      if (typeof inline === "string" && inline.trim()) {
        return inline;
      }
    }
  }
  return "";
}

function normalizeInterpretRequest(body) {
  const model =
    typeof body.model === "string" && body.model.trim()
      ? body.model.trim()
      : "gpt-4.1-mini";
  const maxOutputTokens = Number.isFinite(body.max_output_tokens)
    ? body.max_output_tokens
    : undefined;

  if (Array.isArray(body.input) && body.input.length > 0) {
    return {
      model,
      input: body.input,
      maxOutputTokens,
      errorMessage: ""
    };
  }

  if (Object.prototype.hasOwnProperty.call(body, "text")) {
    if (typeof body.text !== "string" || !body.text.trim()) {
      return {
        model,
        input: [],
        maxOutputTokens,
        errorMessage: "text is required."
      };
    }

    return {
      model,
      input: [
        {
          role: "user",
          content: [{ type: "input_text", text: body.text.trim() }]
        }
      ],
      maxOutputTokens,
      errorMessage: ""
    };
  }

  return {
    model,
    input: [],
    maxOutputTokens,
    errorMessage: "input array is required."
  };
}

function parseBool(value, defaultValue) {
  if (value == null || value === "") {
    return defaultValue;
  }

  switch (String(value).trim().toLowerCase()) {
    case "1":
    case "true":
    case "yes":
    case "on":
      return true;
    case "0":
    case "false":
    case "no":
    case "off":
      return false;
    default:
      return defaultValue;
  }
}

function parsePositiveInt(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ""), 10);
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed;
  }
  return fallback;
}

function resolveRequestToken(req) {
  const bearer = parseBearerToken(req.get("Authorization"));
  if (bearer) {
    return bearer;
  }
  const backendToken = (req.get("X-Backend-Token") || "").trim();
  return backendToken;
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
