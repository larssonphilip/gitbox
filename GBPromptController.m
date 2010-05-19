#import "GBPromptController.h"

@implementation GBPromptController

@synthesize title;
@synthesize promptText;
@synthesize buttonText;
@synthesize value;

@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;

@synthesize payload;

+ (GBPromptController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBPromptController"] autorelease];
}

- (id) initWithWindow:(NSWindow*)window
{
  if (self = [super initWithWindow:window])
  {
    self.title = NSLocalizedString(@"Prompt",@"");
    self.promptText = NSLocalizedString(@"Prompt:",@"");
    self.buttonText = NSLocalizedString(@"OK",@"");
  }
  return self;
}

- (void) dealloc
{
  self.title = nil;
  self.promptText = nil;
  self.buttonText = nil;
  self.value = nil;
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  if (finishSelector) [self.target performSelector:finishSelector withObject:self];
}

- (IBAction) onCancel:(id)sender
{
  if (cancelSelector) [self.target performSelector:cancelSelector withObject:self];
}

@end
