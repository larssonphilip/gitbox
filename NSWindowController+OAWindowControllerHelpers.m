#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation NSWindowController (OAWindowControllerHelpers)

- (void) beginSheetForController:(NSWindowController*)ctrl
{
  [ctrl retain]; // retain for a lifetime of the window
  
  [NSApp beginSheet:[ctrl window]
     modalForWindow:[self window]
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
