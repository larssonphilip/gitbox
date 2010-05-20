
@interface NSWindowController (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl;
- (void) endSheetForController:(NSWindowController*)ctrl;

@end

@interface NSWindow (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl;
- (void) endSheetForController:(NSWindowController*)ctrl;

@end

