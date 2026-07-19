import SwiftUI
import VisionKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    let onResult: (Result<ReceiptScanResult, Error>) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onResult: (Result<ReceiptScanResult, Error>) -> Void
        private let onCancel: () -> Void

        init(
            onResult: @escaping (Result<ReceiptScanResult, Error>) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onResult = onResult
            self.onCancel = onCancel
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onResult(.failure(error))
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map(scan.imageOfPage(at:))
            Task { @MainActor in
                do {
                    onResult(.success(try await ReceiptTextRecognizer.recognize(images: images)))
                } catch {
                    onResult(.failure(error))
                }
            }
        }
    }
}
