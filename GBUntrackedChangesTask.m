#import "GBUntrackedChangesTask.h"
#import "GBRepository.h"
#import "GBStage.h"
#import "GBChange.h"

#import "NSData+OADataHelpers.h"

@implementation GBUntrackedChangesTask

- (NSArray*) arguments
{
  return [@"ls-files --other --exclude-standard" componentsSeparatedByString:@" "];
}

- (void) didFinish
{
  [super didFinish];
  GBStage* stage = self.repository.stage;
  if ([self isError])
  {
    stage.untrackedChanges = [NSArray array];
  }
  else
  {
    NSMutableArray* untrackedChanges = [NSMutableArray array];
    for (NSString* path in [[self.output UTF8String] componentsSeparatedByString:@"\n"])
    {
      if (path && [path length] > 0)
      {
        GBChange* change = [[GBChange new] autorelease];
        change.srcURL = [NSURL URLWithString:path relativeToURL:self.repository.url];
        change.repository = self.repository;
        [untrackedChanges addObject:change];
      }
    }
    
    stage.untrackedChanges = untrackedChanges;
  }
  [self updateChangesForCommit:stage];
}

@end
