#import "GBPreferencesController.h"
#import "GBModels.h"
#import "OATask.h"

@implementation GBPreferencesController

@synthesize tabView;
@synthesize updater;

@synthesize isFileMergeAvailable;
@synthesize isKaleidoscopeAvailable;
@synthesize isChangesAvailable;
@synthesize isTextWranglerAvailable;
@synthesize isBBEditAvailable;
@synthesize isAraxisAvailable;


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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    BOOL fm = !![OATask systemPathForExecutable:@"opendiff"];
    BOOL ks = !![OATask systemPathForExecutable:@"ksdiff"];
    BOOL ch = !![OATask systemPathForExecutable:@"chdiff"];
    BOOL tw = !![OATask systemPathForExecutable:@"twdiff"];
    BOOL bb = !![OATask systemPathForExecutable:@"bbdiff"];
    BOOL ax = !![OATask systemPathForExecutable:@"compare"] || !![OATask systemPathForExecutable:@"araxis"];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.isFileMergeAvailable = fm;
      self.isKaleidoscopeAvailable = ks;
      self.isChangesAvailable = ch;
      self.isTextWranglerAvailable = tw;
      self.isBBEditAvailable = bb;
      self.isAraxisAvailable = ax;
    });
  });
}

- (void) windowDidResignKey:(NSNotification *)notification
{
}

- (void) windowWillClose:(NSNotification *)notification
{
}

@end
