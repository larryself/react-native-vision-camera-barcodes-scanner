#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>

#if __has_include("VisionCameraBarcodesScanner/VisionCameraBarcodesScanner-Swift.h")
#import "VisionCameraBarcodesScanner/VisionCameraBarcodesScanner-Swift.h"
#else
#import "VisionCameraBarcodesScanner-Swift.h"
#endif

VISION_EXPORT_SWIFT_FRAME_PROCESSOR(VisionCameraBarcodesScannerPlugin, scanBarcodes)