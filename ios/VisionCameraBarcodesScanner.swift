import Foundation
import VisionCamera
import Vision

@objc(VisionCameraBarcodesScanner)
public class VisionCameraBarcodesScanner: FrameProcessorPlugin {
    private var symbologies: [VNBarcodeSymbology] = []

    public override init(proxy: VisionCameraProxyHolder, options: [AnyHashable: Any]! = [:]) {
        super.init(proxy: proxy, options: options)
        if let options = options["formats"] as? [String] {
            for option in options {
                if let symbology = symbologyFromString(option) {
                    symbologies.append(symbology)
                }
            }
        }
    }

    public override func callback(
        _ frame: Frame,
        withArguments arguments: [AnyHashable: Any]?
    ) -> Any {
        var data: [[String: Any]] = []

        // Извлекаем CVPixelBuffer из CMSampleBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(frame.buffer) else {
            return data
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let request = VNDetectBarcodesRequest { (request, error) in
            guard error == nil, let results = request.results as? [VNBarcodeObservation] else {
                return
            }

            for observation in results {
                let barcodeData: [String: Any] = [
                    "type": observation.symbology.rawValue,
                    "data": observation.payloadStringValue ?? "",
                    "bounds": [
                        "origin": [
                            "x": observation.boundingBox.origin.x,
                            "y": observation.boundingBox.origin.y
                        ],
                        "size": [
                            "width": observation.boundingBox.size.width,
                            "height": observation.boundingBox.size.height
                        ]
                    ]
                ]
                data.append(barcodeData)
            }
        }

        if !symbologies.isEmpty {
            request.symbologies = symbologies
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Error detecting barcodes: \(error)")
        }

        return data
    }

    private func symbologyFromString(_ barcodeType: String) -> VNBarcodeSymbology? {
        switch barcodeType {
        case "aztec":
            return .aztec
        case "code-39":
            return .code39
        case "code-93":
            return .code93
        case "code-128":
            return .code128
        case "data-matrix":
            return .dataMatrix
        case "ean-8":
            return .ean8
        case "ean-13":
            return .ean13
        case "itf":
            return .itf14
        case "pdf-417":
            return .pdf417
        case "qr":
            return .qr
        case "upc-e":
            return .upce
        case "codabar":
            if #available(iOS 15.0, *) {
                return .codabar
            } else {
                return nil
            }
        case "all":
            return nil // Все типы по умолчанию
        default:
            return nil
        }
    }
}
