import VisionCamera
import Vision
import UIKit

@objc(VisionCameraBarcodesScannerPlugin)
public class VisionCameraBarcodesScannerPlugin: FrameProcessorPlugin {
    private var symbologies: [VNBarcodeSymbology] = []

    public override init(proxy: VisionCameraProxyHolder, options: [AnyHashable: Any]! = [:]) {
        super.init(proxy: proxy, options: options)

        // Обработка переданных опций
        if let options = options {
            for value in options.values {
                if let valueList = value as? [Any] {
                    for format in valueList {
                        if let formatString = format as? String {
                            switch formatString {
                            case "code_128": symbologies.append(.code128)
                            case "code_39": symbologies.append(.code39)
                            case "code_93": symbologies.append(.code93)
                            case "codabar": symbologies.append(.codabar)
                            case "ean_13": symbologies.append(.ean13)
                            case "ean_8": symbologies.append(.ean8)
                            case "itf": symbologies.append(.itf14)
                            case "upc_e": symbologies.append(.upce)
                            case "upc_a": symbologies.append(.upce) // UPC-A не поддерживается напрямую, используем UPC-E
                            case "qr": symbologies.append(.qr)
                            case "pdf_417": symbologies.append(.pdf417)
                            case "aztec": symbologies.append(.aztec)
                            case "data_matrix": symbologies.append(.dataMatrix)
                            case "all": symbologies.append(contentsOf: VNDetectBarcodesRequest.supportedSymbologies)
                            default: break
                            }
                        }
                    }
                }
            }
        }

        // Если форматы не указаны, используем все
        if symbologies.isEmpty {
            symbologies = VNDetectBarcodesRequest.supportedSymbologies
        }
    }

    public override func callback(_ frame: Frame, withArguments arguments: [AnyHashable: Any]?) -> Any? {
        let buffer = frame.buffer
        let orientation = frame.orientation

        // Преобразование буфера кадра в CIImage
        guard let ciImage = CIImage(cvPixelBuffer: buffer) else {
            return nil
        }

        // Создание запроса для обнаружения штрих-кодов
        let request = VNDetectBarcodesRequest { [weak self] (request, error) in
            guard let self = self else { return }
            if let error = error {
                print("Ошибка при обнаружении штрих-кода: \(error)")
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                return
            }

            // Преобразование результатов в массив
            var data: [[String: Any]] = []
            for barcode in results {
                let objData = self.processData(barcode: barcode)
                data.append(objData)
            }

            // Возврат данных (если нужно)
            // Здесь можно отправить данные через событие или другой механизм
        }

        // Установка форматов штрих-кодов
        request.symbologies = symbologies

        // Обработка изображения
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: getCGImageOrientation(from: orientation), options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Ошибка при обработке кадра: \(error)")
        }

        return nil
    }

    private func processData(barcode: VNBarcodeObservation) -> [String: Any] {
        var objData: [String: Any] = [:]

        // Координаты штрих-кода
        let boundingBox = barcode.boundingBox
        objData["width"] = boundingBox.width
        objData["height"] = boundingBox.height
        objData["top"] = boundingBox.minY
        objData["bottom"] = boundingBox.maxY
        objData["left"] = boundingBox.minX
        objData["right"] = boundingBox.maxX

        // Значение штрих-кода
        objData["rawValue"] = barcode.payloadStringValue
        objData["displayValue"] = barcode.payloadStringValue

        // Тип штрих-кода
        objData["format"] = barcode.symbology.rawValue

        return objData
    }

    private func getCGImageOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
