#import <AppKit/AppKit.h>

#define GBApp ((GBApplication*)NSApp)

@interface GBApplication : NSApplication

- (void) beginIgnoreUserAttentionRequests;
- (void) endIgnoreUserAttentionRequests;

@end
