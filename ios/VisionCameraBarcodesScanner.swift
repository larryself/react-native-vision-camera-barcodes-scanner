import VisionCamera

@objc(VisionCameraBarcodesScannerPlugin)
public class VisionCameraBarcodesScannerPlugin: FrameProcessorPlugin {
  public override init(proxy: VisionCameraProxyHolder, options: [AnyHashable: Any]! = [:]) {
    super.init(proxy: proxy, options: options)
  }

  public override func callback(_ frame: Frame, withArguments arguments: [AnyHashable: Any]?) -> Any? {
    let buffer = frame.buffer
    let orientation = frame.orientation
    // code goes here
    return nil
  }
}