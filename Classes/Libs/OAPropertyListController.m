#import "OAPropertyListController.h"
#import "OAFile.h"

@implementation OAPropertyListController

@synthesize plistURL;
@synthesize plist;

- (void) dealloc
{
  if (isDirty)
  {
    NSException *exception = [NSException exceptionWithName:@"Not synchronized when deallocated"
      reason:@"OAPropertyListController is deallocated when out of sync! You should call -synchronize."  userInfo:nil];
    @throw exception;
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id) plist
{
  if (!plist)
  {
    self.plist = [OAFile mutablePropertyListForPath:[self.plistURL path]];
    if (!plist)
    {
      self.plist = [NSMutableDictionary dictionary];
    }
  }
  return plist;
}




#pragma mark Getting Values

- (id) objectForKey:(NSString*)name
{
  return [self.plist objectForKey:name];
}




#pragma mark Setting Values

- (void)setObject:(id)value forKey:(NSString *)name
{
  [self.plist setObject:value forKey:name];
  [self synchronizeLater];
}





#pragma mark Maintaining Persistence


- (void) synchronizeLater
{
  isDirty = YES;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(synchronize) object:nil];
  [self performSelector:@selector(synchronize) withObject:nil afterDelay:0.0];
}

- (BOOL) synchronizeIfNeeded
{
  if (!isDirty) return YES;
  return [self synchronize];
}

- (BOOL) synchronize
{
  isDirty = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(synchronize) object:nil];
  [OAFile setPropertyList:self.plist forPath:[self.plistURL path]];
  return YES;
}

@end
