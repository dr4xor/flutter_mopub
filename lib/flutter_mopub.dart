import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterMopub {
  static MethodChannel _channel = const MethodChannel('flutter_mopub')..setMethodCallHandler(_handleMethodCall);
  static const testAdUnitId = '920b6145fb1546cf8b5cf2ac34638bb7';
  static bool _isInitilized = false;

  static bool get isInitilized {
    if (!_isInitilized) {
      print(
          'Flutter Mopub Plugin not initilized. Please call method FlutterMopub.initilize() before using any property');
    }
    return _isInitilized;
  }

  static final RewardedVideoAd _rewardedVideoAdInstance =
      RewardedVideoAd._(_channel);

  static RewardedVideoAd get rewardedVideoAdInstance {
    return _rewardedVideoAdInstance;
  }

  static final PersonalInfoManager _personalInfoManager =
      PersonalInfoManager._(_channel);
  static PersonalInfoManager getPersonalInformationManager() {
    return _personalInfoManager;
  }

  /// Handle incoming method calls
  static Future _handleMethodCall(MethodCall call) async {
    var m = call.method;
    if(m.startsWith('PersonalInfoManager.')) {
      _personalInfoManager?._onMethodCall(call);
      return;
    }
    rewardedVideoAdInstance?._onMethodCall(call);
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
    await _channel.invokeMethod('setRewardedVideoListener', {'enable': true});
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

class RewardedVideoAd {
  final MethodChannel _channel;

  List<Function> _listeners = [];

  RewardedVideoAd._(this._channel);

  void _onMethodCall(MethodCall call) {
    RewardedVideoAdEvent event = _convertStringToEvent(call.method);
    _listeners.forEach((listener) => listener(event, call.arguments));
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
    return null;
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
  ///
  ///Returns an Id.
  ///
  ///Use this Id for listener removal.
  int addRewardedVideoListener(
      {@required
          Function(RewardedVideoAdEvent event, dynamic arguments) listener}) {
    assert(FlutterMopub.isInitilized != false);
    _listeners.add(listener);
    return _listeners.length - 1;
  }

  ///Remove listener for rewarded video events
  bool removeRewardedVideoListener(int id) {
    assert(FlutterMopub.isInitilized != false);
    if (id < 0 || id >= _listeners.length) return false;
    _listeners.removeAt(id);
    return true;
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

class PersonalInfoManager{
  final MethodChannel _channel;

  Function onConsentDialogLoaded;
  Function(String errorCode) onConsentDialogLoadFailed;

  PersonalInfoManager._(this._channel);

  void _onMethodCall(MethodCall call) {
    print(call.method);
    var method = call.method.substring(call.method.indexOf('.') + 1);
    print(method);
    if(method == "onConsentDialogLoaded") {
      onConsentDialogLoaded?.call();
    }
    if(method == "onConsentDialogLoadFailed") {
      onConsentDialogLoadFailed?.call(call.arguments['moPubErrorCode']);
    }
  }

  Future<bool> shouldShowConsentDialog() async {
    assert(FlutterMopub.isInitilized);
    return _channel.invokeMethod<bool>('shouldShowConsentDialog');
  }

  Future<void> loadConsentDialog (
      Function onConsentDialogLoaded,
      Function(String errorCode) onConsentDialogLoadFailed) async {
    assert(FlutterMopub.isInitilized);

    this.onConsentDialogLoaded = onConsentDialogLoaded;
    this.onConsentDialogLoadFailed = onConsentDialogLoadFailed;

    return _channel.invokeMethod<void>('loadConsentDialog');
  }

  Future<bool> showConsentDialog() async {
    assert(FlutterMopub.isInitilized != false);
    return _channel.invokeMethod<bool>('showConsentDialog');
  }
}
