package com.visioncamerabarcodesscanner

import android.net.Uri
import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableNativeArray
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_ALL_FORMATS
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_AZTEC
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODABAR
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_128
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_39
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_93
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_DATA_MATRIX
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_EAN_13
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_EAN_8
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_ITF
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_PDF417
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_QR_CODE
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_UPC_A
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_UPC_E
import com.google.mlkit.vision.common.InputImage

class ImageScanner(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private var barcodeOptions = BarcodeScannerOptions.Builder()

    @ReactMethod
    fun process(uri: String, options: ReadableArray?, promise: Promise) {
        Log.d(NAME, "Starting process method")

        // Логирование переданных опций
        Log.d(NAME, "Options: ${options?.toArrayList()?.joinToString(", ")}")

        options?.toArrayList()?.forEach {
            when (it) {
                "code_128" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_CODE_128)
                    Log.d(NAME, "Added FORMAT_CODE_128 to barcode options")
                }
                "code_39" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_CODE_39)
                    Log.d(NAME, "Added FORMAT_CODE_39 to barcode options")
                }
                "code_93" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_CODE_93)
                    Log.d(NAME, "Added FORMAT_CODE_93 to barcode options")
                }
                "codabar" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_CODABAR)
                    Log.d(NAME, "Added FORMAT_CODABAR to barcode options")
                }
                "ean_13" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_EAN_13)
                    Log.d(NAME, "Added FORMAT_EAN_13 to barcode options")
                }
                "ean_8" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_EAN_8)
                    Log.d(NAME, "Added FORMAT_EAN_8 to barcode options")
                }
                "itf" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_ITF)
                    Log.d(NAME, "Added FORMAT_ITF to barcode options")
                }
                "upc_e" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_UPC_E)
                    Log.d(NAME, "Added FORMAT_UPC_E to barcode options")
                }
                "upc_a" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_UPC_A)
                    Log.d(NAME, "Added FORMAT_UPC_A to barcode options")
                }
                "qr" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_QR_CODE)
                    Log.d(NAME, "Added FORMAT_QR_CODE to barcode options")
                }
                "pdf_417" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_PDF417)
                    Log.d(NAME, "Added FORMAT_PDF417 to barcode options")
                }
                "aztec" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_AZTEC)
                    Log.d(NAME, "Added FORMAT_AZTEC to barcode options")
                }
                "data-matrix" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_DATA_MATRIX)
                    Log.d(NAME, "Added FORMAT_DATA_MATRIX to barcode options")
                }
                "all" -> {
                    barcodeOptions.setBarcodeFormats(FORMAT_ALL_FORMATS)
                    Log.d(NAME, "Added FORMAT_ALL_FORMATS to barcode options")
                }
            }
        }

        val scanner = BarcodeScanning.getClient(barcodeOptions.build())
        Log.d(NAME, "Barcode scanner initialized")

        val parsedUri = Uri.parse(uri)
        Log.d(NAME, "Parsed URI: $parsedUri")

        val image = InputImage.fromFilePath(this.reactApplicationContext, parsedUri)
        Log.d(NAME, "InputImage created from file path")

        val task: Task<List<Barcode>> = scanner.process(image)
        Log.d(NAME, "Barcode scanning task started")

        try {
            val barcodes: List<Barcode> = Tasks.await(task)
            Log.d(NAME, "Barcode scanning task completed. Found ${barcodes.size} barcodes")

            val data = WritableNativeArray()
            for (barcode in barcodes) {
                val map = VisionCameraBarcodesScannerModule.processData(barcode)
                data.pushMap(map)
                Log.d(NAME, "Processed barcode: ${barcode.rawValue}")
            }

            promise.resolve(data)
            Log.d(NAME, "Promise resolved with barcode data")
        } catch (e: Exception) {
            Log.e(NAME, "Error processing barcode: ${e.message}", e)
            promise.reject("BARCODE_SCAN_ERROR", e)
        }
    }

    override fun getName() = NAME

    companion object {
        const val NAME = "ImageScanner"
    }
}
