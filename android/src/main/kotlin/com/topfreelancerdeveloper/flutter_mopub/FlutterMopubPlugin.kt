package com.topfreelancerdeveloper.flutter_mopub

import android.app.Activity
import android.util.Log

import com.mopub.common.MediationSettings
import com.mopub.common.MoPub
import com.mopub.common.SdkConfiguration
import com.mopub.common.privacy.ConsentDialogListener
import com.mopub.mobileads.MoPubErrorCode

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** FlutterMopubPlugin  */
class FlutterMopubPlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "flutter_mopub")
        FlutterMopubPlugin.channel = channel
        val mediationSettingsChannel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "flutter_mopub/mediationSettings")
        channel.setMethodCallHandler(FlutterMopubPlugin())
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "initilize") {
            val adUnitId = call.argument<String>("adUnitId")
            if (adUnitId == null || adUnitId.isEmpty()) {
                result.error("10", "ad_unit_id is null or empty", null)
                return
            }
            val adapterConfigurationClass: String

            val legitimateInterestAllowed: Boolean

            val mediatedNetworkConfigurationClass: String
            val mediatedNetworkConfiguration: Map<String, String>

            val mopubRequestOptionsClass: String
            val mopubRequestOptionsConfiguration: Map<String, String>

            val settings: Array<MediationSettings>

            val config = SdkConfiguration.Builder(adUnitId).build()

            MoPub.initializeSdk(activity, config) {
                RewardedVideoAd.createInstance(activity, FlutterMopubPlugin.channel)
                result.success(true)
            }
        } else if ("loadRewardedVideo" == call.method) {
            val adUnitId = call.argument<String>("adUnitId")
            if (adUnitId == null || adUnitId.isEmpty()) {
                result.error("10", "ad_unit_id is null or empty", null)
                return
            }
            result.success(RewardedVideoAd.instance?.load(adUnitId))
        } else if ("setRewardedVideoListener" == call.method) {
            if (call.argument<Any>("enable") == null || call.argument<Any>("enable") !is Boolean) {
                result.error("10", "enable property is null or it it not a boolean", null)
                return
            }
            RewardedVideoAd.instance?.setListenerProvided(call.argument<Any>("enable") as Boolean)
            result.success(true)
        } else if ("setApplyRateLimiting" == call.method) {
            if (call.argument<Any>("apply") == null || call.argument<Any>("apply") !is Boolean) {
                result.error("10", "apply property is null or it it not a boolean", null)
                return
            }
            RewardedVideoAd.instance?.setApplyRateLimiting(call.argument<Any>("apply") as Boolean)
            result.success(true)
        } else if ("showRewardedVideo" == call.method) {
            val adUnitId = call.argument<String>("adUnitId")
            val customData = call.argument<String>("customData")
            if (adUnitId == null || adUnitId.isEmpty()) {
                result.error("10", "ad_unit_id is null or empty", null)
                return
            }
            if (customData != null) {
                if (customData.toByteArray().size > 8 * 1000) {
                    Log.i(TAG, "cusom data size exceeds mopub recommended size of 8kb")
                }
            }
            result.success(RewardedVideoAd.instance?.show(adUnitId, call.argument<Any>("customData") as String?))
        } else if ("shouldShowConsentDialog" == call.method) {
            val personalInfoManager = MoPub.getPersonalInformationManager()
            if (personalInfoManager == null) {
                result.error("10", "PersonalInformationManager is not available", null)
                return
            }
            result.success(personalInfoManager.shouldShowConsentDialog());
        } else if ("loadConsentDialog" == call.method) {
            val personalInfoManager = MoPub.getPersonalInformationManager();
            if (personalInfoManager == null) {
                result.error("10", "PersonalInformationManager is not available", null)
                return
            }
            val consentDialogListener = object : ConsentDialogListener {
                override fun onConsentDialogLoaded() {
                    channel.invokeMethod("PersonalInfoManager.onConsentDialogLoaded", null)
                }

                override fun onConsentDialogLoadFailed(moPubErrorCode: MoPubErrorCode) {
                    channel.invokeMethod("PersonalInfoManager.onConsentDialogLoadFailed", mapOf("moPubErrorCode" to moPubErrorCode.name))
                }
            }
            personalInfoManager.loadConsentDialog(consentDialogListener)
            result.success(true)
        } else if ("showConsentDialog" == call.method) {
            val personalInfoManager = MoPub.getPersonalInformationManager();
            if (personalInfoManager == null) {
                result.error("10", "PersonalInformationManager is not available", null)
                return
            }
            result.success(personalInfoManager.showConsentDialog());

        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    companion object {

        private lateinit var activity: Activity
        private lateinit var channel: MethodChannel
        public val TAG:String = "FlutterMopbPlugin"

        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_mopub")
            FlutterMopubPlugin.channel = channel
            activity = registrar.activity()
            channel.setMethodCallHandler(FlutterMopubPlugin())
        }
    }
}
