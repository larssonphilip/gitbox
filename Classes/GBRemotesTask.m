#import "GBRemotesTask.h"
#import "GBRemote.h"

@interface GBRemotesTask ()
@property(nonatomic, strong) NSMutableDictionary* remotesByAlias;
@end

@implementation GBRemotesTask

@synthesize remotes;
@synthesize remotesByAlias;


- (NSArray*) arguments
{
  return [@"config --get-regexp remote.*.(url|fetch)" componentsSeparatedByString:@" "];
}

- (GBRemote*) remoteForAlias:(NSString*)alias
{
  if (!self.remotesByAlias)
  {
    self.remotesByAlias = [NSMutableDictionary dictionary];
  }
  GBRemote* aRemote = [self.remotesByAlias objectForKey:alias];
  if (!aRemote)
  {
    aRemote = [GBRemote new];
    aRemote.alias = alias;
    aRemote.repository = self.repository;
    [self.remotesByAlias setObject:aRemote forKey:alias];
  }
  return aRemote;
}

- (void) didFinish
{
  [super didFinish];
  NSMutableArray* list = [NSMutableArray array];
  for (NSString* line in [[self UTF8OutputStripped] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      NSArray* keyAndValue = [line componentsSeparatedByString:@" "];
      if (keyAndValue && keyAndValue.count >= 2)
      {
        NSString* key = [keyAndValue objectAtIndex:0];
        NSString* value = [[keyAndValue subarrayWithRange:NSMakeRange(1, keyAndValue.count-1)] componentsJoinedByString:@" "];
        
        NSRange r1 = [key rangeOfString:@"remote."];
        NSRange r2 = [key rangeOfString:@".url"];
        NSRange r3 = [key rangeOfString:@".fetch"];
        
        if (r1.location == 0)
        {
          if (r2.length > 0 && (r2.location + r2.length) == [key length])
          {
            GBRemote* remote = [self remoteForAlias:[key substringWithRange:NSMakeRange(r1.length, [key length] - r1.length - r2.length)]];
            remote.URLString = value;
            [list addObject:remote];
          }
          else if (r3.length > 0 && (r3.location + r3.length) == [key length])
          {
            GBRemote* remote = [self remoteForAlias:[key substringWithRange:NSMakeRange(r1.length, [key length] - r1.length - r3.length)]];
            remote.fetchRefspec = value;
          }
          else
          {
            NSLog(@"ERROR: expected remote.<alias>.(url|fetch), got: %@", key);
          }
        }
        else
        {
          NSLog(@"ERROR: expected remote.<alias>.(url|fetch), got: %@", key);
        }
      }
      else
      {
        NSLog(@"ERROR: expected '<key> <value>', got: %@", line);
      } // if line is valid
    } // if line not empty
  } // for loop
  
  self.remotes = list;
}


@end
