#import "OAActivityIndicator.h"

OAActivityIndicator* sharedOAActivityIndicator;
@implementation OAActivityIndicator

@synthesize value;

+ (OAActivityIndicator*)sharedIndicator
{
  if (sharedOAActivityIndicator == nil)
  {
    sharedOAActivityIndicator = [self new];
  }
	return sharedOAActivityIndicator;
}

- (void) updateValueOnUnknownThread:(BOOL)v
{
  [self performSelectorOnMainThread:
   @selector(updateValueOnMainThread:) withObject:
   [NSNumber numberWithBool:v] waitUntilDone:NO];
}

- (void) updateValueOnMainThread:(BOOL)v
{
  //NSLog(@"active: %d", (NSInteger)v);
  self.value = v;
  #if TARGET_OS_IPHONE
    [UIApplication sharedApplication].networkActivityIndicatorVisible = value;
  #endif
}

- (void) push
{
  count++;
  //NSLog(@"push: %d", count);
  if (count == 1) [self updateValueOnMainThread:YES];
}

- (void) pop
{
  //NSLog(@"pop: %d", count);
  count--;
  if (count == 0) [self updateValueOnMainThread:NO];
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
