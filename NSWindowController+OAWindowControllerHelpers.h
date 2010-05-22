// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSWindowController (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl;
- (void) endSheetForController:(NSWindowController*)ctrl;

@end

@interface NSWindow (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl;
- (void) endSheetForController:(NSWindowController*)ctrl;

@end

