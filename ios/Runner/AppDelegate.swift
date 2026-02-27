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
          let providers = networkInfo.serviceSubscriberCellularProviders ?? [:]

          var all: [[String: Any]] = []

          for (key, carrier) in providers {
            all.append([
              "serviceId": key,
              "carrierName": carrier.carrierName ?? "",
              "mcc": carrier.mobileCountryCode ?? "",
              "mnc": carrier.mobileNetworkCode ?? "",
              "isoCountryCode": carrier.isoCountryCode ?? ""
            ])
          }

          let primary = all.first ?? [:]

          result([
            "primary": primary,
            "all": all
          ])

        } else {
          if let carrier = networkInfo.subscriberCellularProvider {
            let primary: [String: Any] = [
              "serviceId": "subscriberCellularProvider",
              "carrierName": carrier.carrierName ?? "",
              "mcc": carrier.mobileCountryCode ?? "",
              "mnc": carrier.mobileNetworkCode ?? "",
              "isoCountryCode": carrier.isoCountryCode ?? ""
            ]

            result([
              "primary": primary,
              "all": [primary]
            ])
          } else {
            result([
              "primary": [:],
              "all": []
            ])
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
