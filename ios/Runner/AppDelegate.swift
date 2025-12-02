import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps will be configured dynamically from Flutter side with Firebase keys
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup method channel for dynamic Google Maps configuration
    if let controller = window?.rootViewController as? FlutterViewController {
      let googleMapsChannel = FlutterMethodChannel(
        name: "com.maikelgalvao.partiu/google_maps",
        binaryMessenger: controller.binaryMessenger
      )
      
      googleMapsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "setApiKey" {
          if let args = call.arguments as? [String: Any],
             let apiKey = args["apiKey"] as? String {
            GMSServices.provideAPIKey(apiKey)
            result("Google Maps API Key configured")
          } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "API Key is required", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
