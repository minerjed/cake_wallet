#import "CwXCashPlugin.h"
#if __has_include(<cw_xcash/cw_xcash-Swift.h>)
#import <cw_xcash/cw_xcash-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cw_xcash-Swift.h"
#endif

@implementation CwXCashPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwXCashPlugin registerWithRegistrar:registrar];
}
@end
