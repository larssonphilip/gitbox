#import "GBRepositorySettingsViewController.h"

@implementation GBRepositorySettingsViewController

@synthesize title;

- (void) dealloc
{
  [title release]; title = nil;
  [super dealloc];
}

- (void) userDidCancel
{
  // override in subclasses to do some cleanup when window is closed
}

- (void) userDidSave
{
  // override in subclasses
}

@end
