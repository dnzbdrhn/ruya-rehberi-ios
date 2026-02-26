import AVFoundation
import Foundation

final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var currentFileURL: URL?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let filename = "dream-\(UUID().uuidString).m4a"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw AudioRecorderError.couldNotStart
        }

        self.recorder = recorder
        self.currentFileURL = fileURL
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        defer { currentFileURL = nil }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return currentFileURL
    }
}

enum AudioRecorderError: LocalizedError {
    case couldNotStart

    var errorDescription: String? {
        switch self {
        case .couldNotStart:
            return "Ses kaydi baslatilamadi."
        }
    }
}
