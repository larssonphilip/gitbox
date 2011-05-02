@interface GBWindowControllerWithCallback : NSWindowController

@property(nonatomic, copy) void(^completionHandler)(BOOL cancelled);

// For subclasses
- (void) performCompletionHandler:(BOOL)cancelled;

@end
