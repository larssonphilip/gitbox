#import "GBRepositorySettingsController.h"
#import "GBRepositorySettingsViewController.h"
#import "GBRepository.h"

@implementation GBRepositorySettingsViewController

@synthesize settingsController;
@synthesize repository;
@synthesize title;
@synthesize dirty;

- (void) dealloc
{
  [repository release]; repository = nil;
  [title release]; title = nil;
  [super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
  if ((self = [self initWithNibName:[NSString stringWithFormat:@"%@", [self class]] bundle:nil]))
  {
    self.repository = repo;
  }
  return self;
}

- (void) setDirty:(BOOL)flag
{
  if (dirty == flag) return;
  dirty = flag;
  [self.settingsController viewControllerDidChangeDirtyStatus:self];
}

- (void) viewDidLoad
{
  [[self view] setNextResponder:self];
}

- (void) userDidCancel
{
  // override in subclasses to do some cleanup when window is closed
}

- (void) userDidSave
{
  // override in subclasses to save date after the window is closed
}

@end
