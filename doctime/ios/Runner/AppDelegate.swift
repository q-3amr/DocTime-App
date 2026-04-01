import UIKit
import Flutter
import GoogleMaps // 1. تأكد إنك ضفت هاي

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. حط مفتاح الـ iOS هون
    GMSServices.provideAPIKey("AIzaSyDUaQjJKBcmhN7JEcZbspwfOImC35-bFaw")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}