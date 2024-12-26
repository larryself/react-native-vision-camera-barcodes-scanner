import Foundation
import React
import Vision
import UIKit

@objc(ImageScanner)
class ImageScanner: NSObject {

    @objc(process:options:withResolver:withRejecter:)
    private func process(
        uri: String,
        options: NSArray?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // Загрузка изображения
        guard let image = UIImage(contentsOfFile: uri) else {
            reject("IMAGE_LOAD_ERROR", "Failed to load image from URI", nil)
            return
        }

        // Преобразование изображения в CIImage
        guard let ciImage = CIImage(image: image) else {
            reject("IMAGE_CONVERSION_ERROR", "Failed to convert image to CIImage", nil)
            return
        }

        // Создание запроса для обнаружения штрих-кодов
        let request = VNDetectBarcodesRequest { (request, error) in
            if let error = error {
                reject("PROCESSING_ERROR", "Failed to process image", error)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                resolve([]) // Нет штрих-кодов
                return
            }

            // Преобразование результатов в массив
            var data: [[String: Any]] = []
            for barcode in results {
                let objData = self.processData(barcode: barcode)
                data.append(objData)
            }

            resolve(data)
        }

        // Установка форматов штрих-кодов (если указаны)
        if let options = options {
            var symbologies: [VNBarcodeSymbology] = []
            for value in options {
                if let format = value as? String {
                    switch format {
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
            request.symbologies = symbologies
        }

        // Обработка изображения
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            reject("PROCESSING_ERROR", "Failed to process image", error)
        }
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
}
