import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterMopub {
  static const MethodChannel _channel = const MethodChannel('flutter_mopub');
  static bool _isInitilized = false;

  _RewardedVideoAd _rewardedVideoAdInstance = _RewardedVideoAd(_channel);

  _RewardedVideoAd get rewardedVideoAdInstance {
    if(!_isInitilized){
      print('Flutter Mopub Plugin not initilized. Please call method FlutterMopub.initilize() before using any property');
      return null;
    }
    return _rewardedVideoAdInstance;
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> initilize({@required String adUnitId}) async {
    assert(adUnitId != null && adUnitId.isNotEmpty);
    bool inited = await _channel.invokeMethod<bool>('initilize', {'adUnitId': adUnitId});
    _isInitilized = inited;
  }
}

class _RewardedVideoAd {
  final MethodChannel _channel;

  _RewardedVideoAd(this._channel);

  Future<void> setApplyRateLimiting(bool apply) async {
    assert(apply != null);
    await _channel.invokeMethod<void>('setApplyRateLimiting', {'apply': apply});
  }

  Future<void> setRewardedVideoListener(){

  }

  Future<int> load({@required String adUnitId}) {
     //0 = first time load , 1 = load after failure, 2 = load after ratelimiting lifted, 3 = load after closed
     //-1 = already trying to load or loaded or its on screen , -2 = rate limitation
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel
        .invokeMethod<int>('loadRewardedVideo', {'adUnitId': adUnitId});
  }

  Future<int> show({@required String adUnitId , String customData}) {
     //0 = show , 1 = isShowing , -1 = not loaded
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel
        .invokeMethod<int>('loadRewardedVideo', {'adUnitId': adUnitId , 'customData' : customData});
  }
}
