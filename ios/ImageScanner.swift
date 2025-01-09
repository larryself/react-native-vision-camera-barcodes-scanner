import Foundation
import React
import Vision
import UIKit

@objc(ImageScanner)
class ImageScanner: NSObject {

    @objc(process:options:withResolver:withRejecter:)
    private func process(uri: String, options: NSArray?, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let url = URL(string: uri) else {
            reject("INVALID_URI", "Invalid URI provided", nil)
            return
        }

        guard let image = UIImage(contentsOfFile: url.path) else {
            reject("INVALID_IMAGE", "Failed to load image from URI", nil)
            return
        }

        guard let ciImage = CIImage(image: image) else {
            reject("INVALID_IMAGE", "Failed to convert image to CIImage", nil)
            return
        }

        // Настройка запроса для обнаружения штрих-кодов
        let request = VNDetectBarcodesRequest { (request, error) in
            if let error = error {
                reject("DETECTION_ERROR", error.localizedDescription, nil)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                reject("NO_RESULTS", "No barcodes found", nil)
                return
            }

            var data: [[String: Any]] = []

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

            resolve(data)
        }

        // Установка типов штрих-кодов для обнаружения
        if let options = options as? [String] {
            var symbologies: [VNBarcodeSymbology] = []
            for option in options {
                if let symbology = self.symbologyFromString(option) {
                    symbologies.append(symbology)
                }
            }
            request.symbologies = symbologies
        }

        // Выполнение запроса
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                reject("DETECTION_ERROR", error.localizedDescription, nil)
            }
        }
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
        case "all":
            return nil // Все типы по умолчанию
        default:
            return nil
        }
    }
}
