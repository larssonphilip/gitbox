@interface GBWindowControllerWithCallback : NSWindowController

@property(nonatomic, copy) void(^completionHandler)(BOOL cancelled);

- (void) presentSheetInMainWindow;

// For subclasses
- (void) performCompletionHandler:(BOOL)cancelled;

@end
