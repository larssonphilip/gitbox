#import "OANetworkActivityIndicator.h"

OANetworkActivityIndicator* sharedOANetworkActivityIndicator;
@implementation OANetworkActivityIndicator

@synthesize value;

+ (OANetworkActivityIndicator*)sharedIndicator
{
  @synchronized(self)
  {
    if (sharedOANetworkActivityIndicator == nil)
    {
      sharedOANetworkActivityIndicator = [self new];
    }
  }
	return sharedOANetworkActivityIndicator;
}

+ (OANetworkActivityIndicator*)instance // keeping for compatibility with OAHTTPDownload
{
  return [self sharedIndicator];
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
