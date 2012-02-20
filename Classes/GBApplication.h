#import <AppKit/AppKit.h>

#define GBApp ((GBApplication*)NSApp)

@interface GBApplication : NSApplication

@property(nonatomic, assign) BOOL didTerminateSafely;

- (void) beginIgnoreUserAttentionRequests;
- (void) endIgnoreUserAttentionRequests;

@end
