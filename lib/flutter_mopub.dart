import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterMopub {
  static const MethodChannel _channel = const MethodChannel('flutter_mopub');
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

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

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

  Future<void> setApplyRateLimiting(bool apply) async {
    assert(FlutterMopub.isInitilized != false);
    assert(apply != null);
    await _channel.invokeMethod<void>('setApplyRateLimiting', {'apply': apply});
  }

  Future<void> setRewardedVideoListener(
      {@required
          Function(RewardedVideoAdEvent event, dynamic arguments)
              listener}) async {
    assert(FlutterMopub.isInitilized != false);
    _listener = listener;
    await _channel.invokeMethod('setRewardedVideoListener', {'enable': true});
  }

  Future<int> load({@required String adUnitId}) {
    //0 = first time load , 1 = load after failure, 2 = load after ratelimiting lifted, 3 = load after closed
    //-1 = already trying to load or loaded or its on screen , -2 = rate limitation
    assert(FlutterMopub.isInitilized != false);
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel
        .invokeMethod<int>('loadRewardedVideo', {'adUnitId': adUnitId});
  }

  Future<int> show({@required String adUnitId, String customData}) {
    //0 = show , 1 = isShowing , -1 = not loaded
    assert(FlutterMopub.isInitilized != false);
    assert(adUnitId != null && adUnitId.isNotEmpty);
    return _channel.invokeMethod<int>(
        'showRewardedVideo', {'adUnitId': adUnitId, 'customData': customData});
  }
}
