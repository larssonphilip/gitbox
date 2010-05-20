#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation NSWindowController (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl
{
  [[self window] beginSheetForController:ctrl];
}

- (void) endSheetForController:(NSWindowController*)ctrl
{
  [[self window] endSheetForController:ctrl];
}

@end

@implementation NSWindow (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl
{
  [ctrl retain]; // retain for a lifetime of the window
  
  [NSApp beginSheet:[ctrl window]
     modalForWindow:self
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];  
}

- (void) endSheetForController:(NSWindowController*)ctrl
{
  [ctrl autorelease]; // balance with a retain above
  [NSApp endSheet:[ctrl window]];
  [[ctrl window] orderOut:self];
}

@end

