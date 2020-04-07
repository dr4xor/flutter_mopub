import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_mopub/flutter_mopub.dart';

const String ad_unit_id_test = '920b6145fb1546cf8b5cf2ac34638bb7';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterMopub.platformVersion;
      FlutterMopub.initilize(adUnitId: ad_unit_id_test).then((res) async {
        print('result : ' + res.toString());
        await FlutterMopub.rewardedVideoAdInstance.setRewardedVideoListener(listener: (event , arguments) async {
          print(event.toString());
          if(event == RewardedVideoAdEvent.SUCCESS){
            print(arguments);
            print( await FlutterMopub.rewardedVideoAdInstance.show(adUnitId: ad_unit_id_test));
            return;
          }
          print(arguments);
        });
        print( await FlutterMopub.rewardedVideoAdInstance.load(adUnitId: ad_unit_id_test));
      }).catchError((err){
        print('error : ' + err.toString());
      });
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
