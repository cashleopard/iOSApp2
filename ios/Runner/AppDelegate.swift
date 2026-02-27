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

    // MethodChannel to expose SIM MCC/MNC to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sim_info",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        guard call.method == "getMccMnc" else {
          result(FlutterMethodNotImplemented)
          return
        }

        let networkInfo = CTTelephonyNetworkInfo()

        if #available(iOS 13.0, *) {
          // Dual-SIM capable: return all providers, plus a "primary" best guess
          let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]

          var all: [[String: Any]] = []
          for (key, carrier) in providers {
            all.append([
              "serviceId": key,
              "carrierName": carrier.carrierName ?? NSNull(),
              "mcc": carrier.mobileCountryCode ?? NSNull(),
              "mnc": carrier.mobileNetworkCode ?? NSNull(),
              "isoCountryCode": carrier.isoCountryCode ?? NSNull()
            ])
          }

          // Pick first non-nil MCC/MNC as "primary"
          let primary = all.first { item in
            let mcc = item["mcc"]
            let mnc = item["mnc"]
            return !(mcc is NSNull) && !(mnc is NSNull)
          } ?? all.first

          result([
            "primary": primary ?? NSNull(),
            "all": all
          ])
        } else {
          // iOS 12 and below
          if let carrier = networkInfo.subscriberCellularProvider {
            result([
              "primary": [
                "serviceId": "subscriberCellularProvider",
                "carrierName": carrier.carrierName ?? NSNull(),
                "mcc": carrier.mobileCountryCode ?? NSNull(),
                "mnc": carrier.mobileNetworkCode ?? NSNull(),
                "isoCountryCode": carrier.isoCountryCode ?? NSNull()
              ],
              "all": [[
                "serviceId": "subscriberCellularProvider",
                "carrierName": carrier.carrierName ?? NSNull(),
                "mcc": carrier.mobileCountryCode ?? NSNull(),
                "mnc": carrier.mobileNetworkCode ?? NSNull(),
                "isoCountryCode": carrier.isoCountryCode ?? NSNull()
              ]]
            ])
          } else {
            result([
              "primary": NSNull(),
              "all": []
            ])
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
