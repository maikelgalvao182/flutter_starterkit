import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK API Key (iOS) - DEVE vir ANTES de GeneratedPluginRegistrant
    GMSServices.provideAPIKey("AIzaSyBHlCReMj7dEaA-e0dguSe45roNoU1HKXA")
    print("✅ Google Maps API Key configurada")
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
