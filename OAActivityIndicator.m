#import "OAActivityIndicator.h"

OAActivityIndicator* sharedOAActivityIndicator;
@implementation OAActivityIndicator

@synthesize value;

+ (OAActivityIndicator*)sharedIndicator
{
  @synchronized(self)
  {
    if (sharedOAActivityIndicator == nil)
    {
      sharedOAActivityIndicator = [self new];
    }
  }
	return sharedOAActivityIndicator;
}

- (void) updateValueOnUnknownThread:(BOOL)v
{
  [self performSelectorOnMainThread:
   @selector(updateValueOnMainThread:) withObject:
   [NSNumber numberWithBool:v] waitUntilDone:NO];
}

- (void) updateValueOnMainThread:(NSNumber*)v
{
  self.value = [v boolValue];
  #if TARGET_OS_IPHONE
    [UIApplication sharedApplication].networkActivityIndicatorVisible = value;
  #endif
}

- (void) push
{
  @synchronized(self)
  {
    count++;
    if (count == 1) [self updateValueOnUnknownThread:YES];
  }
}

- (void) pop
{
  @synchronized(self)
	{
    count--;
    if (count == 0) [self updateValueOnUnknownThread:NO];
  }
}

- (BOOL) isActive
{
  return count > 0;
}

+ (void) push
{
  [[self sharedIndicator] push];
}

+ (void) pop
{
  [[self sharedIndicator] pop];
}

+ (BOOL) isActive
{
  return [[self sharedIndicator] isActive];
}
@end
