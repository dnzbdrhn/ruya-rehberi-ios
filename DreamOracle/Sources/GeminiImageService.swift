import Foundation
import UIKit

struct GeminiImageService {
    private let session: URLSession
    private let baseURL: URL
    private let optionalAuthToken: String?

    init(
        session: URLSession = .shared,
        baseURL: URL = BackendImageConfiguration.resolveBaseURL(),
        optionalAuthToken: String? = BackendImageConfiguration.resolveOptionalAuthToken()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.optionalAuthToken = optionalAuthToken
    }

    // Compatibility initializer: API key is ignored because image generation now goes through backend proxy.
    init(apiKey _: String, session: URLSession = .shared) {
        self.init(session: session)
    }

    func generateDreamArtwork(title: String, keywords: [String], mood: String, dreamText: String) async throws -> Data {
        try BackendImageConfiguration.validateRuntimeBaseURL(baseURL)
        var request = makeJSONRequest(path: "v1/dream/image")

        let keywordLine = keywords.isEmpty ? String(localized: "image.keywords.fallback") : keywords.joined(separator: ", ")
        let visualMood = softenedVisualMood(from: mood)
        let prompt = """
        Create a symbolic and poetic dream artwork with a gentle, cinematic tone.
        Title concept: \(title)
        Symbol set: \(keywordLine)
        Mood direction: \(visualMood)
        Composition: square (1:1), edge-to-edge full bleed.
        Output canvas: exactly 1024x1024 pixels.
        Visual style: dreamy painterly illustration, semi-abstract symbolism, soft brushwork, atmospheric depth.
        Color palette: indigo + lavender + moonlit blue + warm amber highlights.
        Lighting: soft glow, mystical twilight, calm and reflective ambience.
        Use symbolic metaphors and archetypal objects; narrative can be suggested but not literal.
        Avoid horror, dread, grotesque elements, scary faces, demonic imagery, disturbing body distortion, or oppressive darkness.
        Avoid photorealism and avoid cartoon/comic style.
        Keep composition elegant, balanced, and emotionally uplifting.
        Interpret context metaphorically: \(dreamText)
        No text, no captions, no letters, no logos, no UI, no cards, no borders, no frame, no watermark, no white margins, no letterboxing.
        Return a full-bleed single artwork only.
        """

        let body = BackendImageGenerateRequest(
            prompt: prompt,
            size: "1024x1024",
            seed: nil,
            style: nil
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(BackendImageGenerateResponse.self, from: data)
        let cleaned = (decoded.imageBase64 ?? "").replacingOccurrences(of: "\n", with: "")
        if let imageData = Data(base64Encoded: cleaned) {
            return Self.normalizeGeneratedImageData(imageData)
        }

        throw GeminiImageServiceError.invalidResponse(String(localized: "error.image.data_missing"))
    }

    private func makeJSONRequest(path: String) -> URLRequest {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(normalizedPath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
#if DEBUG || ALLOW_PLIST_TEST_TOKEN
        if let token = optionalAuthToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
#endif
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GeminiImageServiceError.invalidResponse(String(localized: "error.http.response_missing"))
        }
        guard (200...299).contains(http.statusCode) else {
            if let envelope = try? JSONDecoder().decode(BackendMessageErrorEnvelope.self, from: data) {
                throw GeminiImageServiceError.apiError(envelope.error.message)
            }
            if let envelope = try? JSONDecoder().decode(BackendStringErrorEnvelope.self, from: data) {
                throw GeminiImageServiceError.apiError(envelope.error)
            }
            throw GeminiImageServiceError.apiError(
                String(
                    format: String(localized: "error.http.status_format"),
                    locale: .autoupdatingCurrent,
                    http.statusCode
                )
            )
        }
    }

    private func softenedVisualMood(from mood: String) -> String {
        let lower = mood.lowercased()
        if lower.contains("korkunç") || lower.contains("korkunc") {
            return "mysterious yet safe, symbolic and healing, no fear-driven imagery"
        }
        if lower.contains("kaygılı") || lower.contains("kaygili") {
            return "tense but hopeful, calm and stabilizing moonlight"
        }
        if lower.contains("kafası karışık") || lower.contains("kafasi karisik") {
            return "enigmatic but clear-hearted, contemplative and balanced"
        }
        if lower.contains("huzurlu") {
            return "serene, graceful and comforting"
        }
        if lower.contains("harika") {
            return "inspiring, luminous and uplifting"
        }
        return "calm, reflective and slightly magical"
    }

    // Normalize output to stable, full-bleed square artwork so UI frame never shows white bars.
    static func normalizedUIImage(from data: Data) -> UIImage? {
        UIImage(data: normalizeGeneratedImageData(data))
    }

    private static func normalizeGeneratedImageData(_ data: Data) -> Data {
        guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
            return data
        }

        let trimmed = Self.trimLightBorders(from: cgImage)
        let square = Self.centerCrop(trimmed, toAspectRatio: 1.0)
        let tightened = Self.insetCrop(square, byFraction: 0.018)

        guard let rendered = Self.render(cgImage: tightened, size: CGSize(width: 1024, height: 1024)) else {
            return data
        }
        return UIImage(cgImage: rendered).jpegData(compressionQuality: 0.94) ?? data
    }

    private static func trimLightBorders(from image: CGImage) -> CGImage {
        guard let provider = image.dataProvider, let rawData = provider.data else {
            return image
        }
        guard let bytes = CFDataGetBytePtr(rawData) else {
            return image
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bytesPerPixel = max(image.bitsPerPixel / 8, 4)

        guard width > 8, height > 8 else { return image }

        func pixelComponents(x: Int, y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
            let offset = y * bytesPerRow + x * bytesPerPixel
            let r = Int(bytes[offset])
            let g = Int(bytes[offset + min(1, bytesPerPixel - 1)])
            let b = Int(bytes[offset + min(2, bytesPerPixel - 1)])
            let a = Int(bytes[offset + min(3, bytesPerPixel - 1)])
            return (r, g, b, a)
        }

        func isLightOrTransparent(_ rgba: (r: Int, g: Int, b: Int, a: Int)) -> Bool {
            let maxChannel = max(rgba.r, max(rgba.g, rgba.b))
            let minChannel = min(rgba.r, min(rgba.g, rgba.b))
            let brightness = (rgba.r + rgba.g + rgba.b) / 3
            let nearWhite = rgba.r > 238 && rgba.g > 238 && rgba.b > 238
            let paleLowSat = brightness > 214 && (maxChannel - minChannel) < 22
            let transparent = rgba.a < 32
            return nearWhite || paleLowSat || transparent
        }

        func rowLooksLikeBorder(_ y: Int) -> Bool {
            let step = max(1, width / 220)
            var edgeLike = 0
            var samples = 0
            for x in stride(from: 0, to: width, by: step) {
                samples += 1
                if isLightOrTransparent(pixelComponents(x: x, y: y)) {
                    edgeLike += 1
                }
            }
            return samples > 0 && Double(edgeLike) / Double(samples) > 0.96
        }

        func columnLooksLikeBorder(_ x: Int) -> Bool {
            let step = max(1, height / 220)
            var edgeLike = 0
            var samples = 0
            for y in stride(from: 0, to: height, by: step) {
                samples += 1
                if isLightOrTransparent(pixelComponents(x: x, y: y)) {
                    edgeLike += 1
                }
            }
            return samples > 0 && Double(edgeLike) / Double(samples) > 0.96
        }

        var top = 0
        var bottom = height - 1
        var left = 0
        var right = width - 1

        let maxTrimY = Int(Double(height) * 0.24)
        let maxTrimX = Int(Double(width) * 0.24)

        while top < maxTrimY, top < bottom, rowLooksLikeBorder(top) {
            top += 1
        }
        while (height - 1 - bottom) < maxTrimY, bottom > top, rowLooksLikeBorder(bottom) {
            bottom -= 1
        }
        while left < maxTrimX, left < right, columnLooksLikeBorder(left) {
            left += 1
        }
        while (width - 1 - right) < maxTrimX, right > left, columnLooksLikeBorder(right) {
            right -= 1
        }

        let cropWidth = right - left + 1
        let cropHeight = bottom - top + 1

        guard cropWidth > width / 2, cropHeight > height / 2 else {
            return image
        }

        let rect = CGRect(x: left, y: top, width: cropWidth, height: cropHeight)
        return image.cropping(to: rect) ?? image
    }

    private static func centerCrop(_ image: CGImage, toAspectRatio targetAspect: CGFloat) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let currentAspect = width / height

        var cropRect = CGRect(x: 0, y: 0, width: width, height: height)

        if currentAspect > targetAspect {
            let targetWidth = height * targetAspect
            cropRect.origin.x = (width - targetWidth) / 2
            cropRect.size.width = targetWidth
        } else if currentAspect < targetAspect {
            let targetHeight = width / targetAspect
            cropRect.origin.y = (height - targetHeight) / 2
            cropRect.size.height = targetHeight
        }

        guard let cropped = image.cropping(to: cropRect.integral) else {
            return image
        }
        return cropped
    }

    private static func insetCrop(_ image: CGImage, byFraction fraction: CGFloat) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let insetX = max(0, width * fraction)
        let insetY = max(0, height * fraction)
        let rect = CGRect(
            x: insetX,
            y: insetY,
            width: max(1, width - (insetX * 2)),
            height: max(1, height - (insetY * 2))
        ).integral

        guard rect.width > 1, rect.height > 1, let cropped = image.cropping(to: rect) else {
            return image
        }
        return cropped
    }

    private static func render(cgImage: CGImage, size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return context.makeImage()
    }
}

private enum BackendImageConfiguration {
    private static let fallbackBaseURL = URL(string: "https://backend.example.com")!
    private static let placeholderHost = "backend.example.com"

    static func resolveBaseURL() -> URL {
        let raw = ((Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if
            let url = URL(string: raw),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            !raw.isEmpty
        {
            return url
        }
        return fallbackBaseURL
    }

    static func validateRuntimeBaseURL(_ baseURL: URL) throws {
#if DEBUG
        _ = baseURL
#else
        let host = (baseURL.host ?? "").lowercased()
        if host.isEmpty || host == placeholderHost {
            throw GeminiImageServiceError.backendBaseURLMissing
        }
#endif
    }

    static func resolveOptionalAuthToken() -> String? {
#if DEBUG
        if let envToken = normalizedToken(ProcessInfo.processInfo.environment["BACKEND_AUTH_TOKEN"] ?? "") {
            return envToken
        }
#else
#if !ALLOW_PLIST_TEST_TOKEN
        return nil
#endif
#endif

#if ALLOW_PLIST_TEST_TOKEN
        return normalizedToken((Bundle.main.object(forInfoDictionaryKey: "BACKEND_AUTH_TOKEN") as? String) ?? "")
#else
        return nil
#endif
    }

    private static func normalizedToken(_ rawToken: String) -> String? {
        let value = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

private struct BackendImageGenerateRequest: Encodable {
    let prompt: String
    let size: String?
    let seed: Int?
    let style: String?
}

private struct BackendImageGenerateResponse: Decodable {
    let imageBase64: String?

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
    }
}

private struct BackendMessageErrorEnvelope: Decodable {
    let error: BackendMessageError
}

private struct BackendMessageError: Decodable {
    let message: String
}

private struct BackendStringErrorEnvelope: Decodable {
    let error: String
}

enum GeminiImageServiceError: LocalizedError {
    case apiError(String)
    case invalidResponse(String)
    case backendBaseURLMissing

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return String(
                format: String(localized: "error.gemini.api_format"),
                locale: .autoupdatingCurrent,
                message
            )
        case .invalidResponse(let message):
            return String(
                format: String(localized: "error.gemini.invalid_response_format"),
                locale: .autoupdatingCurrent,
                message
            )
        case .backendBaseURLMissing:
            return String(localized: "error.backend.base_url_missing")
        }
    }
}
