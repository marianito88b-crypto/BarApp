import UIKit
import Flutter
import GoogleMaps // ⬅️ DEBE ESTAR

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ⬅️ ¡REVISA ESTA LÍNEA!
    GMSServices.provideAPIKey("AIzaSyD4E9CRU8E8s4aSRiUDo6_tOOgFSPJDO7c") 
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}