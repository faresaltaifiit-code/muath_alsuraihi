import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pendingPrayerNotificationKey = "pending_prayer_notification_payload"
  private var prayerNotificationsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications on iOS so notification taps are
    // delivered to the app delegate (and can open the complete prayer audio).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    do {
      let widgetChannel = FlutterMethodChannel(
        name: "com.faresaltaifi.muath_alsuraihi/prayer_widget",
        binaryMessenger: messenger
      )
      widgetChannel.setMethodCallHandler { call, result in
        guard call.method == "savePrayerSnapshot", let snapshot = call.arguments,
              JSONSerialization.isValidJSONObject(snapshot),
              let defaults = UserDefaults(suiteName: "group.com.faresaltaifi.muathalsuraihi.widgets") else {
          result(FlutterError(code: "widget_snapshot_unavailable", message: nil, details: nil))
          return
        }
        do {
          let data = try JSONSerialization.data(withJSONObject: snapshot)
          defaults.set(data, forKey: "prayer_widget_snapshot")
          WidgetCenter.shared.reloadTimelines(ofKind: "PrayerWidget")
          result(nil)
        } catch { result(FlutterError(code: "widget_snapshot_invalid", message: error.localizedDescription, details: nil)) }
      }
      let downloadsChannel = FlutterMethodChannel(
        name: "com.faresaltaifi.muath_alsuraihi/downloads",
        binaryMessenger: messenger
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
        binaryMessenger: messenger
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
