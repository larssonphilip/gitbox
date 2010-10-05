#import "GBModels.h"
#import "GBUntrackedChangesTask.h"

#import "NSData+OADataHelpers.h"

@implementation GBUntrackedChangesTask

- (NSArray*) arguments
{
  return [@"ls-files --other --exclude-standard" componentsSeparatedByString:@" "];
}

- (BOOL) avoidIndicator
{
  return YES;
}

// overriden to match the ls-files output format
- (NSArray*) changesFromDiffOutput:(NSData*) data
{
  NSMutableArray* untrackedChanges = [NSMutableArray array];
  for (NSString* path in [[data UTF8String] componentsSeparatedByString:@"\n"])
  {
    if (path && [path length] > 0)
    {
      GBChange* change = [[GBChange new] autorelease];
      change.srcURL = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                             relativeToURL:self.repository.url];
      change.repository = self.repository;
      [untrackedChanges addObject:change];
    }
  }
  
  return untrackedChanges;
}

@end
