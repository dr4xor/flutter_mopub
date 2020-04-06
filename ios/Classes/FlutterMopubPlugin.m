#import "FlutterMopubPlugin.h"
#if __has_include(<flutter_mopub/flutter_mopub-Swift.h>)
#import <flutter_mopub/flutter_mopub-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mopub-Swift.h"
#endif

@implementation FlutterMopubPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMopubPlugin registerWithRegistrar:registrar];
}
@end
