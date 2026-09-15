import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let downloadsChannel = FlutterMethodChannel(
        name: "com.faresaltaifi.muath_alsuraihi/downloads",
        binaryMessenger: controller.binaryMessenger
      )
      downloadsChannel.setMethodCallHandler { call, result in
        guard call.method == "excludeFromBackup",
              let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }

        do {
          let fileUrl = URL(fileURLWithPath: path)
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          try fileUrl.setResourceValues(values)
          result(nil)
        } catch {
          result(FlutterError(
            code: "backup_exclusion_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
