#if os(iOS)
import SwiftUI
import VisionKit

/// The system document camera: finds the page edges, flattens and crops each page. Hands back the pages as JPEGs.
/// Only on a device with a camera (VNDocumentCameraViewController.isSupported); the simulator has none.
struct Scanner: UIViewControllerRepresentable {
    var done: ([Data]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let c = VNDocumentCameraViewController(); c.delegate = context.coordinator; return c
    }
    func updateUIViewController(_ c: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: Scanner
        init(_ p: Scanner) { parent = p }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.done((0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0).jpegData(compressionQuality: 0.8) })
            parent.dismiss()
        }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) { parent.dismiss() }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError error: Error) { parent.dismiss() }
    }
}
#endif
