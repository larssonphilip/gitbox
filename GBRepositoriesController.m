#import "GBRepositoriesController.h"

@implementation GBRepositoriesController
@synthesize target;
@synthesize action;

- (IBAction) onOK:(id)sender
{
  [self.target performSelector:self.action withObject:self];
}

@end
