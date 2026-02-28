import UIKit
import Flutter
import CoreTelephony

@main
@objc class AppDelegate: FlutterAppDelegate {

  // Keep this alive, otherwise update notifier can get dropped
  private let networkInfo = CTTelephonyNetworkInfo()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("❌ rootViewController is not FlutterViewController / window is nil")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Optional: log when iOS thinks providers changed
    if #available(iOS 13.0, *) {
      networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { serviceId in
        print("📶 providers updated: \(serviceId)")
      }
    }

    let channel = FlutterMethodChannel(name: "sim_info", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(FlutterError(code: "NO_SELF", message: nil, details: nil)); return }

      print("✅ MethodChannel call received: \(call.method)")

      guard call.method == "getMccMnc" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let payload = self.readCarrierPayload()
      result(payload)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func readCarrierPayload() -> [String: Any] {
    if #available(iOS 13.0, *) {
      let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]
      print("📡 providers count: \(providers.count)")

      var all: [[String: Any]] = []

      for (serviceId, carrier) in providers {
        var item: [String: Any] = [:]
        item["serviceId"] = serviceId
        item["carrierName"] = carrier.carrierName ?? NSNull()
        item["mcc"] = carrier.mobileCountryCode ?? NSNull()
        item["mnc"] = carrier.mobileNetworkCode ?? NSNull()
        item["isoCountryCode"] = carrier.isoCountryCode ?? NSNull()
        all.append(item)

        print("📶 provider \(serviceId): \(item)")
      }

      // Choose first provider that has mcc+mnc if present; else just first
      let primary: [String: Any] =
        all.first(where: { $0["mcc"] is String && $0["mnc"] is String })
        ?? all.first
        ?? [:]

      return [
        "ok": true,
        "providersCount": all.count,
        "primary": primary,
        "all": all
      ]
    } else {
      // iOS 12 fallback
      guard let carrier = networkInfo.subscriberCellularProvider else {
        return [
          "ok": false,
          "error": "NO_CARRIER",
          "providersCount": 0,
          "primary": [:],
          "all": []
        ]
      }

      let primary: [String: Any] = [
        "serviceId": "subscriberCellularProvider",
        "carrierName": carrier.carrierName ?? NSNull(),
        "mcc": carrier.mobileCountryCode ?? NSNull(),
        "mnc": carrier.mobileNetworkCode ?? NSNull(),
        "isoCountryCode": carrier.isoCountryCode ?? NSNull()
      ]

      return [
        "ok": true,
        "providersCount": 1,
        "primary": primary,
        "all": [primary]
      ]
    }
  }
}
