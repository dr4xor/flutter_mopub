import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mopub/flutter_mopub.dart';

void main() {
  FlutterMopub.initilize(adUnitId: FlutterMopub.testAdUnitId)
      .then((didInitilize) {
    if (didInitilize) {
      runApp(MyApp());
    } else {
      print('Mopub plugin initilize error');
    }
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RewardedVideoAdEvent _event;
  @override
  void initState() {
    super.initState();
    loadAndShowAd();
  }

  Future<void> loadAndShowAd() async {
    //Add listener to catch events
    FlutterMopub.rewardedVideoAdInstance.setRewardedVideoListener(
        listener: (event, args) {
      setState(() {
        _event = event;
      });
      if (event == RewardedVideoAdEvent.SUCCESS) {
        //ad is loaded now show the add
        FlutterMopub.rewardedVideoAdInstance
            .show(adUnitId: FlutterMopub.testAdUnitId);
      }
    });

    //load ad
    int loadOutcome = await FlutterMopub.rewardedVideoAdInstance
        .load(adUnitId: FlutterMopub.testAdUnitId);
    if (loadOutcome >= 0) {
      //successfully added Ad to loading queue
      print('ad is in loading queue');
    } else {
      //failed to add Ad to loading queue
      print('failed to load ad : errCode = $loadOutcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MoPub example app'),
        ),
        body: Center(
          child: Text('Ad Status: $_event'),
        ),
      ),
    );
  }
}
