import UIKit
import Flutter
import CoreTelephony

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("❌ rootViewController is not FlutterViewController / window is nil")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(name: "sim_info", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, result in
      print("✅ MethodChannel call received: \(call.method)")

      guard call.method == "getMccMnc" else {
        DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
        return
      }

      let networkInfo = CTTelephonyNetworkInfo()

      if #available(iOS 13.0, *) {
        let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]
        print("📡 providers count: \(providers.count)")

        var all: [[String: Any]] = []
        for (key, carrier) in providers {
          let item: [String: Any] = [
            "serviceId": key,
            "carrierName": carrier.carrierName ?? "nil",
            "mcc": carrier.mobileCountryCode ?? "nil",
            "mnc": carrier.mobileNetworkCode ?? "nil",
            "isoCountryCode": carrier.isoCountryCode ?? "nil"
          ]
          all.append(item)
          print("📶 provider \(key): \(item)")
        }

        let primary = all.first(where: { ($0["mcc"] as? String) != "nil" && ($0["mnc"] as? String) != "nil" })
          ?? all.first
          ?? [:]

        let payload: [String: Any] = [
          "ok": true,
          "providersCount": all.count,
          "primary": primary,
          "all": all
        ]

        DispatchQueue.main.async { result(payload) }
        return
      }

      // iOS 12 fallback (won't run on iPhone 12 usually)
      if let carrier = networkInfo.subscriberCellularProvider {
        let primary: [String: Any] = [
          "serviceId": "subscriberCellularProvider",
          "carrierName": carrier.carrierName ?? "nil",
          "mcc": carrier.mobileCountryCode ?? "nil",
          "mnc": carrier.mobileNetworkCode ?? "nil",
          "isoCountryCode": carrier.isoCountryCode ?? "nil"
        ]

        let payload: [String: Any] = [
          "ok": true,
          "providersCount": 1,
          "primary": primary,
          "all": [primary]
        ]

        DispatchQueue.main.async { result(payload) }
      } else {
        let payload: [String: Any] = [
          "ok": false,
          "error": "NO_CARRIER",
          "providersCount": 0,
          "primary": [:],
          "all": []
        ]
        DispatchQueue.main.async { result(payload) }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
