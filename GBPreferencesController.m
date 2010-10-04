#import "GBPreferencesController.h"
#import "GBModels.h"
#import "OATask.h"

@implementation GBPreferencesController

@synthesize tabView;
@synthesize isKaleidoscopeAvailable;
@synthesize isChangesAvailable;

- (void) dealloc
{
  self.tabView = nil;
  [super dealloc];
}

- (NSArray*) diffTools
{
  return [GBChange diffTools];
}

- (IBAction) selectDiffToolTab
{
  [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"GBPreferencesTabIndex"];
}

- (IBAction) diffToolDidChange:(id)_
{
}




#pragma mark NSWindowDelegate



- (void) windowDidBecomeKey:(NSNotification *)notification
{
  self.isKaleidoscopeAvailable = !![OATask systemPathForExecutable:@"ksdiff"];
  self.isChangesAvailable = !![OATask systemPathForExecutable:@"chdiff"];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
}

- (void) windowWillClose:(NSNotification *)notification
{
}

@end
