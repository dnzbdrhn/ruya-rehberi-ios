# DreamOracle (iOS)

Ruya yorumlama odakli bir SwiftUI iOS uygulamasi.

Kullanici:
- Ruya metnini yazarak yorum alabilir
- Ses kaydi yapip OpenAI ses-anlama modeli ile yaziya cevirerek yorum alabilir
- Jung odakli detayli ruya yorumu alir
- Ruya yorumu uzerine ucretli soru sorabilir
- Gecmis ruya kayitlarini gorebilir

## Kullandigi OpenAI modelleri

- Ses -> yazi: `gpt-4o-mini-transcribe`
- Ruya yorumu: `gpt-4.1-mini`

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
4. `Secrets.xcconfig.example` dosyasini `Secrets.xcconfig` olarak kopyala:
```bash
cp Secrets.xcconfig.example Secrets.xcconfig
```
5. `Secrets.xcconfig` icinde `OPENAI_API_KEY` (ve gerekiyorsa `GEMINI_API_KEY`) degerlerini doldur.
6. Simulatorde veya cihazda calistir.

## OpenAI API key (local development)

Uygulama OpenAI key'i su sirayla yukler:
1. `Info.plist` icindeki `OPENAI_API_KEY` (Xcode Build Setting'den gelir)
2. Ortam degiskeni `OPENAI_API_KEY` (fallback)

Onerilen yontem:
- `Secrets.xcconfig` dosyasini yerelde kullan
- Bu dosyayi commit etme (`.gitignore` icinde)
- Proje Debug config'inde `Secrets.xcconfig` otomatik okunur

## Ucretlendirme Kurallari

- Her kullanici icin ilk 2 ruya yorumu ucretsiz
- 3. yorumdan itibaren her ruya yorumu: 1 kredi
- Ruya yorumu ile ilgili her ek soru: 1 kredi
- Kredi ve gecmis kayitlar cihazda local olarak saklanir

## Notlar

- Uretim ortaminda API key'i istemcide tutma; kendi backend'in uzerinden proxy et.
