#import "GBCommitController.h"

@implementation GBCommitController

@synthesize message;

@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;

- (void) dealloc
{
  self.message = nil;
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  [self.target performSelector:finishSelector withObject:self];
}

- (IBAction) onCancel:(id)sender
{
  [self.target performSelector:cancelSelector withObject:self];
}

@end
