package com.topfreelancerdeveloper.flutter_mopub;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.mopub.common.MediationSettings;
import com.mopub.common.MoPub;
import com.mopub.common.SdkConfiguration;
import com.mopub.common.SdkInitializationListener;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterMopubPlugin */
public class FlutterMopubPlugin implements MethodCallHandler ,FlutterPlugin , ActivityAware {

    private static Activity activity;
    private static MethodChannel channel;

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding ) {
        MethodChannel channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_mopub");
        FlutterMopubPlugin.channel = channel;
        channel.setMethodCallHandler(new FlutterMopubPlugin());
  }

    public static void registerWith(Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_mopub");
        FlutterMopubPlugin.channel = channel;
        activity = registrar.activity();
        channel.setMethodCallHandler(new FlutterMopubPlugin());
    }


  @Override public void  onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android ${android.os.Build.VERSION.RELEASE}");
    } else if (call.method.equals("initilize")) {
        String adUnitId = call.argument("adUnitId");
        if(adUnitId == null || adUnitId.isEmpty()){
            result.error("10" , "ad_unit_id is null or empty" , null);
            return;
        }
        String adapterConfigurationClass;

        boolean legitimateInterestAllowed;

        String mediatedNetworkConfigurationClass;
        Map<String , String> mediatedNetworkConfiguration;

        String mopubRequestOptionsClass;
        Map<String , String> mopubRequestOptionsConfiguration;

        MediationSettings[] settings;

        SdkConfiguration config = new SdkConfiguration.Builder(adUnitId).build();

        MoPub.initializeSdk(activity, config, new SdkInitializationListener() {
            @Override
            public void onInitializationFinished() {
                RewardedVideoAd.createInstance(activity , FlutterMopubPlugin.channel);
                result.success(true);
            }
        });
    }else if("loadRewardedVideo".equals(call.method)) {
        String adUnitId = call.argument("adUnitId");
        if(adUnitId == null || adUnitId.isEmpty()){
            result.error("10" , "ad_unit_id is null or empty" , null);
            return;
        }
        result.success(RewardedVideoAd.getInstance().load(adUnitId));
    }else  if("setRewardedVideoListener".equals(call.method)) {
        if(call.argument("enable") == null || !(call.argument("enable") instanceof Boolean)){
            result.error("10" , "enable property is null or it it not a boolean" , null);
            return;
        }
        RewardedVideoAd.getInstance().setListenerProvided((boolean) call.argument("enable"));
        result.success(true);
    }else  if("setApplyRateLimiting".equals(call.method)) {
        if(call.argument("apply") == null || !(call.argument("apply") instanceof Boolean)){
            result.error("10" , "apply property is null or it it not a boolean" , null);
            return;
        }
        RewardedVideoAd.getInstance().setApplyRateLimiting((boolean) call.argument("apply"));
        result.success(true);
    }else  if("showRewardedVideo".equals(call.method)) {
        String adUnitId = call.argument("adUnitId");
        if(adUnitId == null || adUnitId.isEmpty() || !(call.argument("customData")!= null && call.argument("customData") instanceof String)){
            result.error("10" , "ad_unit_id is null or empty or custom data is not a sting" , null);
            return;
        }
       result.success(RewardedVideoAd.getInstance().show(adUnitId , (String) call.argument("customData")));
    }
    else {
      result.notImplemented();
    }
  }

  @Override public void  onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding ) {
  }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }
}
