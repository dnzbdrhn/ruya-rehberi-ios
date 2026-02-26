# AGENTS.md — Rüya Rehberi iOS Product Rules

## Product vision
Premium mystical AI-powered dream journal app for global App Store scale.
Tone: elegant, calm, symbolic, slightly “fortune-teller” vibe, but NEVER deterministic.

## Monetization model (Hybrid)
We support BOTH:
A) Auto-renewable subscriptions (Premium): monthly + yearly
B) Consumable credits packs

Rules:
- Free users:
  - Unlimited dream logging
  - 3 lifetime free interpretations total
  - After free quota: 1 interpretation = 1 credit
  - AI image generation = 2 credits
  - Only `Nötr` and `Bilişsel-Davranışsal` philosophy modes are free
- Premium subscribers:
  - Unlimited interpretations
  - Unlimited AI images
  - All philosophy modes unlocked
- Credits and subscription must coexist; do not remove credits logic even if user becomes premium.
- All monetization must be enforced in a single centralized gate (no scattered if-statements).

## Localization rules
- No hardcoded user-facing strings.
- TR + EN required for all new/changed UI strings.
- Dates must respect Locale.

## Interpretation style rules
Each interpretation must output 3 sections:
1) Symbols & meanings (calm, brief)
2) Fortune-style message (probabilistic language, no absolute predictions)
3) Practical reflection (1–3 actionable suggestions)
Avoid medical/legal claims and deterministic statements.

Philosophy modes:
- POPULAR:
  - Astrolojik Lens
  - Çekim Yasası
  - Stoa Felsefesi
- PSYCHOLOGICAL:
  - Nötr (Free)
  - Bilişsel-Davranışsal (Free)
  - Jung Arketipleri
  - Freud Analizi
  - Gestalt Terapisi
- SCIENTIFIC:
  - Nörobilim Görüşü
- SPIRITUAL & RELIGIOUS:
  - İslami Perspektif
  - Sufi Mistisizmi
  - Hristiyan Perspektifi
  - Yahudi Geleneği
  - Kabalist Mistisizmi
  - Hindu Sembolizmi
  - Budist Yaklaşımı
  - Taoist / Çin Halk
  - Shinto (Japon)
  - Yerli / Şamanik

Philosophy mode rules:
- Only `Nötr` and `Bilişsel-Davranışsal` are free; all other modes are Premium-only.
- Each philosophy mode must produce a tone-specific interpretation style.
- All philosophy modes must use probabilistic language.
- Never use deterministic or absolute claims in any mode.

## Architecture rules
- Use StoreKit 2 for IAP.
- Keep Product IDs in one file.
- Central Purchase/Entitlement manager + FeatureGate service.
- Keep code modular and testable; avoid heavy dependencies.
- Prepare for future backend proxy; do not treat client keys as permanent.

## UI rules
- Premium mystical night aesthetic.
- Maintain readability (darker top zone, smoother bottom zone).
- Reusable components must be consistent (GlassCard, buttons, chips).
