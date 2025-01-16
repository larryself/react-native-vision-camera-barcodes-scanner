import Foundation
import React
import ZXingObjC
import CoreImage

@objc(ImageScanner)
class ImageScanner: NSObject {
    static var reader: ZXMultiFormatReader = ZXMultiFormatReader()
    static var multipleReader: ZXGenericMultipleBarcodeReader = ZXGenericMultipleBarcodeReader(delegate: reader)

    @objc(process:options:resolver:rejecter:)
    func process(_ uri: String, options: [String]?, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        print("Начало обработки изображения: \(uri)")
        var returnedResults: [Any] = []

        // Исправление URI
        let imageUrl: URL
        if uri.hasPrefix("file://") {
            guard let url = URL(string: uri) else {
                print("Ошибка: Некорректный URI изображения")
                rejecter("FILE_ERROR", "Не удалось загрузить изображение", nil)
                return
            }
            imageUrl = url
        } else {
            imageUrl = URL(fileURLWithPath: uri)
        }

        print("Изображение загружено по URI: \(imageUrl.path)")

        // Загрузка изображения
        guard let image = UIImage(contentsOfFile: imageUrl.path) else {
            print("Ошибка: Не удалось создать UIImage из файла")
            rejecter("FILE_ERROR", "Не удалось загрузить изображение", nil)
            return
        }
        print("Размер изображения: \(image.size)")

        // Масштабирование изображения
        let scaledImage = self.scaleImage(image, toSize: CGSize(width: 1024, height: 1024))
        guard let cgImage = scaledImage.cgImage else {
            print("Ошибка: Не удалось получить CGImage из UIImage")
            rejecter("FILE_ERROR", "Не удалось загрузить изображение", nil)
            return
        }

        // Создание ZXing объектов
        let source = ZXCGImageLuminanceSource(cgImage: cgImage)
        print("Создан ZXCGImageLuminanceSource")

        guard let bitmap = ZXBinaryBitmap(binarizer: ZXHybridBinarizer(source: source)) else {
            print("Ошибка: Не удалось создать ZXBinaryBitmap")
            rejecter("SCAN_ERROR", "Не удалось создать бинарное изображение", nil)
            return
        }
        print("ZXBinaryBitmap успешно создан")

        do {
            print("Попытка распознавания штрих-кодов...")
            let hints = ZXDecodeHints()
            hints.tryHarder = true
//            hints.addPossibleFormat(kBarcodeFormatQRCode)

            // Распознавание с помощью ZXing
            let results = try ImageScanner.multipleReader.decodeMultiple(bitmap, hints: hints)
            print("Распознавание завершено. Найдено результатов: \(results.count)")

            for result in results {
                if let zxingResult = result as? ZXResult {
                    let rawText = zxingResult.text ?? ""
                    print("Найден штрих-код: \(rawText), формат: \(ImageScanner.nameForBarcodeFormat(zxingResult.barcodeFormat))")

                    // Декодирование текста из Windows-1251
                    if let decodedText = decodeWindows1251(text: rawText) {
                        print("Декодированный текст: \(decodedText)")
                        returnedResults.append(ImageScanner.wrapResult(result: zxingResult, decodedText: decodedText))
                    } else {
                        print("Не удалось декодировать текст.")
                        returnedResults.append(ImageScanner.wrapResult(result: zxingResult, decodedText: rawText))
                    }
                }
            }

            // Если ZXing не нашел QR-код, пробуем CIDetector
            if returnedResults.isEmpty {
                print("Предупреждение: Ни один штрих-код не был распознан ZXing. Пробуем CIDetector...")
                if let ciImage = CIImage(image: image) {
                    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                    let features = detector?.features(in: ciImage) ?? []
                    for feature in features {
                        if let qrFeature = feature as? CIQRCodeFeature {
                            returnedResults.append(["barcodeText": qrFeature.messageString ?? "", "barcodeFormat": "QR Code"])
                        }
                    }
                }
            }

            // Возврат результата
            if returnedResults.isEmpty {
                print("Ошибка: Ни один штрих-код не был распознан")
                rejecter("SCAN_FAILED", "Не удалось распознать штрих-код", nil)
            } else {
                print("Успешно распознано штрих-кодов: \(returnedResults.count)")
                resolver(returnedResults)
            }
        } catch {
            print("Ошибка при распознавании штрих-кодов: \(error.localizedDescription)")
            rejecter("SCAN_FAILED", "Не удалось распознать штрих-код", error)
        }
    }

    // Масштабирование изображения
    func scaleImage(_ image: UIImage, toSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    // Декодирование текста из Windows-1251 в UTF-8
    private func decodeWindows1251(text: String) -> String? {
        guard let latin1Data = text.data(using: .isoLatin1) else {
            print("Ошибка преобразования строки в данные ISO-8859-1")
            return nil
        }

        let windows1251Encoding = CFStringEncodings.windowsCyrillic.rawValue
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(windows1251Encoding))

        let result = latin1Data.withUnsafeBytes { bytes -> String? in
            guard let baseAddress = bytes.baseAddress else { return nil }
            let bufferPointer = UnsafeBufferPointer(start: baseAddress.assumingMemoryBound(to: UInt8.self), count: latin1Data.count)
            return NSString(bytes: bufferPointer.baseAddress!, length: bufferPointer.count, encoding: nsEncoding) as String?
        }

        if let decodedText = result {
            print("Успешно декодировано: \(decodedText)")
            return decodedText
        } else {
            print("Не удалось декодировать данные как Windows-1251")
            return nil
        }
    }

    // Обертка для результата
    static func wrapResult(result: ZXResult, decodedText: String) -> [String: Any] {
        var map: [String: Any] = [:]
        map["displayValue"] = decodedText
        map["barcodeFormat"] = ImageScanner.nameForBarcodeFormat(result.barcodeFormat)
        map["barcodeBytesBase64"] = "" // Добавить логику для байтов, если нужно

        var convertedPoints: [[String: CGFloat]] = []
        if let points = result.resultPoints as? [ZXResultPoint] {
            for point in points {
                convertedPoints.append(["x": CGFloat(point.x), "y": CGFloat(point.y)])
            }
        }
        map["points"] = convertedPoints
        return map
    }

    // Название формата штрих-кода
    static func nameForBarcodeFormat(_ format: ZXBarcodeFormat) -> String {
        switch format {
        case kBarcodeFormatAztec: return "Aztec"
        case kBarcodeFormatCodabar: return "Codabar"
        case kBarcodeFormatCode39: return "Code 39"
        case kBarcodeFormatCode93: return "Code 93"
        case kBarcodeFormatCode128: return "Code 128"
        case kBarcodeFormatDataMatrix: return "Data Matrix"
        case kBarcodeFormatEan8: return "EAN-8"
        case kBarcodeFormatEan13: return "EAN-13"
        case kBarcodeFormatITF: return "ITF"
        case kBarcodeFormatMaxiCode: return "MaxiCode"
        case kBarcodeFormatPDF417: return "PDF417"
        case kBarcodeFormatQRCode: return "QR Code"
        case kBarcodeFormatRSS14: return "RSS 14"
        case kBarcodeFormatRSSExpanded: return "RSS Expanded"
        case kBarcodeFormatUPCA: return "UPC-A"
        case kBarcodeFormatUPCE: return "UPC-E"
        case kBarcodeFormatUPCEANExtension: return "UPC/EAN extension"
        default: return "Unknown"
        }
    }
}
