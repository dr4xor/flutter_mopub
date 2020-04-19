import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterMopub {
  static const MethodChannel _channel = const MethodChannel('flutter_mopub');
  static const testAdUnitId = '920b6145fb1546cf8b5cf2ac34638bb7';
  static bool _isInitilized = false;

  static bool get isInitilized {
    if (!_isInitilized) {
      print(
          'Flutter Mopub Plugin not initilized. Please call method FlutterMopub.initilize() before using any property');
    }
    return _isInitilized;
  }

  static final _RewardedVideoAd _rewardedVideoAdInstance =
      _RewardedVideoAd(_channel);

  static _RewardedVideoAd get rewardedVideoAdInstance {
    return _rewardedVideoAdInstance;
  }
  /// Initilizes the plugin
  /// 
  /// Use  any valid ad unit once per app’s lifecycle, typically on app launch
  /// 
  /// This method must be called before any operation is attempted.
  static Future<bool> initilize({@required String adUnitId}) async {
    assert(adUnitId != null && adUnitId.isNotEmpty);
    bool inited =
        await _channel.invokeMethod<bool>('initilize', {'adUnitId': adUnitId});
    _isInitilized = inited;
    return _isInitilized;
  }
}

enum RewardedVideoAdEvent {
  SUCCESS,
  FAILURE,
  STARTED,
  PLAYBACKERROR,
  CLICKED,
  CLOSED,
  COMPLETED,
}

class _RewardedVideoAd {
  final MethodChannel _channel;

  Function _listener;

  _RewardedVideoAd(this._channel) {
    _channel.setMethodCallHandler((call) async {
      if (_listener != null) {
        _listener(_convertStringToEvent(call.method), call.arguments);
      }
    });
  }

  RewardedVideoAdEvent _convertStringToEvent(String event) {
    if ("onRewardedVideoLoadSuccess" == event) {
      return RewardedVideoAdEvent.SUCCESS;
    }
    if ("onRewardedVideoLoadFailure" == event) {
      return RewardedVideoAdEvent.FAILURE;
    }
    if ("onRewardedVideoStarted" == event) {
      return RewardedVideoAdEvent.STARTED;
    }
    if ("onRewardedVideoPlaybackError" == event) {
      return RewardedVideoAdEvent.PLAYBACKERROR;
    }
    if ("onRewardedVideoClicked" == event) {
      return RewardedVideoAdEvent.CLICKED;
    }
    if ("onRewardedVideoClosed" == event) {
      return RewardedVideoAdEvent.CLOSED;
    }
    if ("onRewardedVideoCompleted" == event) {
      return RewardedVideoAdEvent.COMPLETED;
    }
    print('unimplemented event : $event');
  }
  ///Default is true
  ///More info about Rate Limiting on Mopub docs
  ///
  ///https://developers.mopub.com/publishers/android/rate-limiting/
  Future<void> setApplyRateLimiting(bool apply) async {
    assert(FlutterMopub.isInitilized != false);
    assert(apply != null);
    await _channel.invokeMethod<void>('setApplyRateLimiting', {'apply': apply});
  }
  ///Add listener for rewarded video events
  ///
  ///Check events by RewardedVideoAdEvent enum
  Future<void> setRewardedVideoListener(
      {@required
          Function(RewardedVideoAdEvent event, dynamic arguments)
              listener}) async {
    assert(FlutterMopub.isInitilized != false);
    _listener = listener;
    await _channel.invokeMethod('setRewardedVideoListener', {'enable': true});
  }
  /// Load an ad
  /// 
  /// use [await rewardedVideoAdInstance.load('adUnitId') >= 0]
  /// 
  /// for a successful load condition.
  /// 
  /// returns an integer code which meanings are as follows
  /// 
  /// success :
  /// 
  /// [0] : First time loading ad
  /// 
  /// [1] : Load after previous failure
  /// 
  /// [2] : Load after Rate Limiting lifted
  /// 
  /// [3] : Load after ad is closed
  /// 
  /// failure :
  /// 
  /// [-1] : Already in loading queue
  /// 
  /// [-2] : Rate Limiting
  Future<int> load({@required String adUnitId}) {
    assert(FlutterMopub.isInitilized != false);
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel
        .invokeMethod<int>('loadRewardedVideo', {'adUnitId': adUnitId});
  }
  /// Show an ad
  /// 
  /// use [await rewardedVideoAdInstance.show('adUnitId') >= 0]
  /// 
  /// for a successful show condition.
  /// 
  /// returns an integer code which meanings are as follows
  /// 
  /// success :
  /// 
  /// [0] : Showed
  /// 
  /// [1] : Ad is already showing
  /// 
  /// failure :
  /// 
  /// [-1] : Ad not loaded
  Future<int> show({@required String adUnitId, String customData}) {
    assert(FlutterMopub.isInitilized != false);
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel.invokeMethod<int>(
        'showRewardedVideo', {'adUnitId': adUnitId, 'customData': customData});
  }
}
