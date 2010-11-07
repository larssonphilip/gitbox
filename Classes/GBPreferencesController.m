#import "GBPreferencesController.h"
#import "GBModels.h"
#import "OATask.h"
#import <Sparkle/Sparkle.h>

@implementation GBPreferencesController

@synthesize tabView;
@synthesize updater;
@synthesize isKaleidoscopeAvailable;
@synthesize isChangesAvailable;

- (void) dealloc
{
  self.tabView = nil;
  self.updater = nil;
  [super dealloc];
}

- (NSArray*) diffTools
{
  return [GBChange diffTools];
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
