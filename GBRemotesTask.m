#import "GBRemotesTask.h"
#import "GBRemote.h"

#import "NSData+OADataHelpers.h"

@implementation GBRemotesTask

@synthesize remotes;

- (void) dealloc
{
  self.remotes = nil;
  [super dealloc];
}

- (NSArray*) arguments
{
  return [@"config --get-regexp remote.*.url" componentsSeparatedByString:@" "];
}

- (void) didFinish
{
  [super didFinish];
  NSMutableArray* list = [NSMutableArray array];
  for (NSString* line in [[self.output UTF8String] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      NSArray* keyAndAddress = [line componentsSeparatedByString:@" "]; // ["remote.origin.url", "git@sss.pierlis.com:oleganza/gitbox.git"]
      if (keyAndAddress && [keyAndAddress count] >= 2)
      {
        NSString* key = [keyAndAddress objectAtIndex:0];
        NSString* address = [keyAndAddress objectAtIndex:1];
        NSArray* keyParts = [key componentsSeparatedByString:@"."];
        if (keyParts && [keyParts count] >= 3)
        {
          GBRemote* remote = [[GBRemote new] autorelease];
          remote.URLString = address;
          remote.alias = [keyParts objectAtIndex:1];
          remote.repository = self.repository;
          [list addObject:remote];
        }
        else
        {
          NSLog(@"ERROR: expected remote.<alias>.url, got: %@", key);
        }
      }
      else
      {
        NSLog(@"ERROR: expected '<key> <url>', got: %@", line);
      } // if line is valid
    } // if line not empty
  } // for loop
  self.remotes = list;
}


@end
