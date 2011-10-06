#import "GBRepositorySettingsController.h"
#import "GBRepositorySettingsViewController.h"
#import "GBRepository.h"

@interface GBRepositorySettingsViewController ()
@end

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

- (void) viewDidAppear
{
  // override in subclasses to do view updates
}

- (void) cancel
{
  // override in subclasses to do some cleanup when window is closed
}

- (void) save
{
  // override in subclasses to save date after the window is closed
}

- (BOOL) isDisabled
{
	return self.settingsController.isDisabled;
}

- (void) pushDisabled
{
	[self.settingsController pushDisabled];
}

- (void) popDisabled
{
	[self.settingsController popDisabled];
}

- (NSMutableDictionary*) userInfo
{
	return self.settingsController.userInfo;
}

- (void) criticalConfirmationWithMessage:(NSString*)message description:(NSString*)desc ok:(NSString*)okOrNil completion:(void(^)(BOOL))completion
{
  [self.settingsController criticalConfirmationWithMessage:message description:desc ok:okOrNil completion:completion];
}


@end
