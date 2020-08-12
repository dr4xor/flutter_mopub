import Flutter
import UIKit
import MoPub

public class SwiftFlutterMopubPlugin: NSObject, FlutterPlugin {
    static var channel : FlutterMethodChannel!
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "flutter_mopub", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMopubPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPlatformVersion" {
        result("iOS " + UIDevice.current.systemVersion)
    }else if call.method == "initilize" {
        let adUnitId: String? = (call.arguments as? [String: Any])?["adUnitId"] as? String
        if (adUnitId == nil) {
            result(FlutterError(code: "10", message: "ad_unit_id is null or empty", details: nil))
            return
        }
        let config = MPMoPubConfiguration.init(adUnitIdForAppInitialization: adUnitId!)
        MoPub.sharedInstance().initializeSdk(with: config) {
            RewardedVideoAd.init(channel: SwiftFlutterMopubPlugin.channel)
            result(true)
        }
    }else if "loadRewardedVideo" == call.method{
        let adUnitId: String? = (call.arguments as? [String: Any])?["adUnitId"] as? String
        if (adUnitId == nil) {
            result(FlutterError(code: "10", message: "ad_unit_id is null or empty", details: nil))
            return
        }
        result(RewardedVideoAd.instance.load(adUnitId: adUnitId!))
    }else if "setRewardedVideoListener" == call.method{
        let en: Bool? = (call.arguments as? [String: Any])?["enable"] as? Bool
        if (en == nil) {
            result(FlutterError(code: "10", message: "enable property is null or it it not a boolean", details: nil))
            return
        }
        RewardedVideoAd.instance.setListenerProvided(listen: en!)
        result(true)
    }else if "setApplyRateLimiting" == call.method{
        let en: Bool? = (call.arguments as? [String: Any])?["apply"] as? Bool
        if (en == nil) {
            result(FlutterError(code: "10", message: "apply property is null or it it not a boolean", details: nil))
            return
        }
        RewardedVideoAd.instance.setApplyRateLimiting(apply: en!)
        result(true)
    }else if "showRewardedVideo" == call.method{
        let adUnitId: String? = (call.arguments as? [String: Any])?["adUnitId"] as? String
        let customData: String? = (call.arguments as? [String: Any])?["customData"] as? String
        if (adUnitId == nil) {
            result(FlutterError(code: "10", message: "ad_unit_id is null or empty", details: nil))
            return
        }
        result(RewardedVideoAd.instance.show(adUnitId: adUnitId!, customData: customData))
    }else {
        result(FlutterMethodNotImplemented)
    }
  }
}
