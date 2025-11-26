import UIKit
import Flutter
import GoogleMaps // 1. Add this import
import flutter_background_service_ios

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. Add your API Key call here
    GMSServices.provideAPIKey("AIzaSyAjXZ0JIj6YQAs5FZ9XnP985QEut61lvRU") 
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "your.custom.task.identifier"
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}