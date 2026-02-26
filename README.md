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
4. `DreamOracle/Sources/OwnerSecrets.swift` dosyasinda `openAIAPIKey` degerini kendi key'in ile doldur.
5. Simulatorde veya cihazda calistir.

Alternatif:
- Xcode'da `DreamOracle` target'i icin `Build Settings` altinda `OPENAI_API_KEY` degeri verilirse uygulama onu da kullanir.

## Ucretlendirme Kurallari

- Her kullanici icin ilk 2 ruya yorumu ucretsiz
- 3. yorumdan itibaren her ruya yorumu: 1 kredi
- Ruya yorumu ile ilgili her ek soru: 1 kredi
- Kredi ve gecmis kayitlar cihazda local olarak saklanir

## Notlar

- Demo kolayligi icin API key dogrudan uygulamaya veriliyor.
- Uretim ortaminda API key'i istemcide tutma; kendi backend'in uzerinden proxy et.
