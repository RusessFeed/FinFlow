import UIKit
import Vision

enum ReceiptRecognitionError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: "The selected image could not be read."
        case .noTextFound: "No readable text was found on the receipt."
        }
    }
}

enum ReceiptTextRecognizer {
    static func recognize(images: [UIImage]) async throws -> ReceiptScanResult {
        let lines = try await Task.detached(priority: .userInitiated) {
            try images.flatMap { image in
                guard let cgImage = image.cgImage else { throw ReceiptRecognitionError.invalidImage }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US", "ru-RU"]
                let handler = VNImageRequestHandler(cgImage: cgImage)
                try handler.perform([request])
                return request.results?.compactMap {
                    $0.topCandidates(1).first?.string
                } ?? []
            }
        }.value

        guard !lines.isEmpty else { throw ReceiptRecognitionError.noTextFound }
        return ReceiptParser.parse(lines: lines)
    }
}
