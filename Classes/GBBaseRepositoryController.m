#import "GBBaseRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "OABlockQueue.h"

@implementation GBBaseRepositoryController

@synthesize updatesQueue;
@synthesize autofetchQueue;
@synthesize sidebarSpinner;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.updatesQueue = nil;
  self.autofetchQueue = nil;
  NSLog(@"GBBaseRepositoryController dealloc %@", self);
  [self.sidebarSpinner removeFromSuperview];
  self.sidebarSpinner = nil;
  [super dealloc];
}

- (NSURL*) url
{
  // overriden in subclasses
  return nil;
}


- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return nil;
}

- (NSImage*) icon
{
  NSString* path = [[self url] path];
  if (!path) return nil;
  
  while ([path length] > 0 && ![[NSFileManager defaultManager] fileExistsAtPath:path])
  {
    path = [path stringByDeletingLastPathComponent];
  }
  return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

- (void) initialUpdateWithBlock:(void(^)())block { if (block) block(); }

- (void) start {}
- (void) stop
{
  [self.sidebarSpinner removeFromSuperview];
}

- (void) didSelect
{
}

- (void) cleanupSpinnerIfNeeded
{
  if (![self isSpinning])
  {
    [self.sidebarSpinner removeFromSuperview];
  }
}







@end
