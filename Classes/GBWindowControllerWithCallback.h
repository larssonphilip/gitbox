@interface GBWindowControllerWithCallback : NSWindowController

@property(nonatomic, copy) void(^completionHandler)(BOOL cancelled);

- (void) presentSheetInMainWindow;
- (void) presentSheetInMainWindowSilent:(BOOL)silent;

// For subclasses
- (void) performCompletionHandler:(BOOL)cancelled;

@end
