import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let shareImportChannelName = "com.rechef.app/share_import_auth"
  private let appGroupSuiteName = "group.com.rechef.app"
  private let tokenKey = "firebase_id_token"
  private let apiBaseUrlKey = "api_base_url"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShareImportAuthPlugin") {
      configureShareImportChannel(messenger: registrar.messenger())
    }
  }

  private func configureShareImportChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: shareImportChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "app_delegate_missing", message: "App delegate missing", details: nil))
        return
      }
      guard let defaults = UserDefaults(suiteName: self.appGroupSuiteName) else {
        result(FlutterError(code: "app_group_unavailable", message: "Unable to access App Group defaults", details: nil))
        return
      }
      switch call.method {
      case "setAuthContext":
        guard
          let args = call.arguments as? [String: Any],
          let token = args["token"] as? String,
          let apiBaseUrl = args["apiBaseUrl"] as? String,
          !token.isEmpty,
          !apiBaseUrl.isEmpty
        else {
          result(FlutterError(code: "invalid_args", message: "token and apiBaseUrl are required", details: nil))
          return
        }
        defaults.set(token, forKey: self.tokenKey)
        defaults.set(apiBaseUrl, forKey: self.apiBaseUrlKey)
        result(nil)
      case "clearAuthContext":
        defaults.removeObject(forKey: self.tokenKey)
        defaults.removeObject(forKey: self.apiBaseUrlKey)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
