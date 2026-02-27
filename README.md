# DreamOracle (iOS)

Ruya yorumlama odakli bir SwiftUI iOS uygulamasi.

Kullanici:
- Ruya metnini yazarak yorum alabilir
- Ses kaydi yapip backend proxy uzerinden yaziya cevirerek yorum alabilir
- Jung odakli detayli ruya yorumu alir
- Ruya yorumu uzerine ucretli soru sorabilir
- Gecmis ruya kayitlarini gorebilir

## Mimari (AI)

- iOS istemci OpenAI anahtari tutmaz.
- iOS sadece backend endpoint'lerine gider.
- OpenAI anahtari sadece server ortam degiskeninde bulunur.

## Kurulum

1. XcodeGen kur:
```bash
brew install xcodegen
```
2. Proje dosyasini uret:
```bash
xcodegen generate
```
3. Projeyi ac:
```bash
open DreamOracle.xcodeproj
```
4. `Secrets.xcconfig.example` dosyasini `Secrets.xcconfig` olarak kopyala (opsiyonel lokal ayarlar icin):
```bash
cp Secrets.xcconfig.example Secrets.xcconfig
```
5. `DreamOracle/Info.plist` icinde `BACKEND_BASE_URL` degerini kendi backend adresine ayarla.
6. Simulatorde veya cihazda calistir.

## Local Development (iOS + Server)

- iOS tarafinda `OPENAI_API_KEY` gerekmez.
- Debug icin `BACKEND_BASE_URL` guvenli bir config olarak `Info.plist` uzerinden okunur.
- `BACKEND_AUTH_TOKEN` (opsiyonel) sadece Debug'da environment variable olarak verilebilir.
- Release build `Authorization` header gondermez.

Server'i lokal calistirma:
1. `server/` klasorune gir.
2. `npm install` calistir.
3. `OPENAI_API_KEY` environment variable ayarla.
4. `NODE_ENV=development` ile `npm run dev` baslat.
5. Isteyenler icin lokal auth:
   - `BACKEND_AUTH_TOKEN` tanimla veya
   - varsayilan dev token `dev-local-token` kullan.

Uretim auth:
- `NODE_ENV=production` ve `BACKEND_AUTH_TOKEN` zorunludur.
- `/v1/*` endpointleri `Authorization: Bearer <BACKEND_AUTH_TOKEN>` ister.
- Eksik/gecersiz token: `401 {"error":"unauthorized"}`.

Curl ornegi (production stili):
```bash
curl -s -X POST "http://127.0.0.1:3000/v1/dream/interpret" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BACKEND_AUTH_TOKEN" \
  -d '{"model":"gpt-4.1-mini","input":[{"role":"user","content":[{"type":"input_text","text":"test"}]}]}'
```

## Ucretlendirme Kurallari

- Her kullanici icin ilk 2 ruya yorumu ucretsiz
- 3. yorumdan itibaren her ruya yorumu: 1 kredi
- Ruya yorumu ile ilgili her ek soru: 1 kredi
- Kredi ve gecmis kayitlar cihazda local olarak saklanir

## Notlar

- Uretim ortaminda OpenAI anahtari yalnizca server tarafinda tutulmali.
