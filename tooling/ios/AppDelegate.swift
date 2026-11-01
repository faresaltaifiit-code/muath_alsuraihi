import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pendingPrayerNotificationKey = "pending_prayer_notification_payload"
  private var prayerNotificationsChannel: FlutterMethodChannel?

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
        if call.method == "availableStorage" {
          do {
            let values = try URL(fileURLWithPath: NSHomeDirectory())
              .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            result(values.volumeAvailableCapacityForImportantUsage)
          } catch {
            result(FlutterError(
              code: "available_storage_failed",
              message: error.localizedDescription,
              details: nil
            ))
          }
          return
        }

        guard call.method == "excludeFromBackup",
              let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }

        do {
          var fileUrl = URL(fileURLWithPath: path)
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

      let prayerNotificationsChannel = FlutterMethodChannel(
        name: "com.faresaltaifi.muath_alsuraihi/prayer_notifications",
        binaryMessenger: controller.binaryMessenger
      )
      prayerNotificationsChannel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "takePendingNotificationPayload" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let payload = UserDefaults.standard.string(forKey: self?.pendingPrayerNotificationKey ?? "")
        if let key = self?.pendingPrayerNotificationKey {
          UserDefaults.standard.removeObject(forKey: key)
        }
        result(payload)
      }
      self.prayerNotificationsChannel = prayerNotificationsChannel
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = response.notification.request.content.userInfo["payload"] as? String
    if payload == "open_adhan" || payload == "open_iqama" {
      UserDefaults.standard.set(payload, forKey: pendingPrayerNotificationKey)
      prayerNotificationsChannel?.invokeMethod("notificationTapped", arguments: payload)
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }
}
