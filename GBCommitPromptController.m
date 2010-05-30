#import "GBCommitPromptController.h"

#import "NSString+OAStringHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBCommitPromptController

@synthesize value;
@synthesize textView;
@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;
@synthesize windowHoldingSheet;

+ (GBCommitPromptController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBCommitPromptController"] autorelease];
}

- (void) dealloc
{
  self.value = nil;
  self.textView = nil;
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  self.value = [self.textView string];
  
  if (!self.value || [self.value isEmptyString]) return;
  
  self.value = [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if (finishSelector) [self.target performSelector:finishSelector withObject:self];
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (IBAction) onCancel:(id)sender
{
  if (cancelSelector) [self.target performSelector:cancelSelector withObject:self];
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}


@end
