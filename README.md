# flutter_mopub
![Gitlab pipeline status](https://img.shields.io/gitlab/pipeline/topfreelancerdeveloper/flutter_mopub)

A new Flutter plugin that uses native platform views to show mopub rewarded video ads!

# Installation

1. Depend on it
Add this to your package's pubspec.yaml file:

```dart
dependencies:
  flutter_mopub: ^0.0.1

```

2. Install it
You can install packages from the command line:

with Flutter:

```dart
$ flutter pub get
```

Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

3. Import it
Now in your Dart code, you can use:

```dart
import 'package:flutter_mopub/flutter_mopub.dart';
```
  

### Supported Platforms
- `0.2.0` >= AndroidX
- `10.0` >= iOS

### Supported MoPub features
- Rewarded Video Ads

### Android integration
- Change minimum sdk to 19 :
1. Open app level build.gradle file (android/app/build.gradle)
2. In android->defaultConfig scope change this line
```dart
defaultConfig {
        .
        .
        .
        minSdkVersion 19 //default is 16
        .
        .
        .
        multiDexEnabled true //add this line if you have build errors
    }
```
- In dependencies scope add this line (to resolve conflict between packages. apply only if you face build errors)
```dart
dependencies {
        .
        .
        .
        implementation 'com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava' //add this line
        .
        .
        .
    }
```

### iOS integration
- Change minimum platform target to iOS 10.0 :
1. Open ios/Runner.xcworkspace in xcode
2. In Runner target -> Deployment Info -> change Target to iOS 10.0

- Configure App Transport Security (ATS) :
Add this key value to your ios/Runner/info.plist
```plist
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```
3. view [MoPub ATS guide](https://developers.mopub.com/publishers/ios/integrate/#step-5-configure-app-transport-security-ats) for more info

### View the rest of the documentation on the example tab. 

