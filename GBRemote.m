#import "GBRepository.h"
#import "GBRemote.h"
#import "GBRef.h"

#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBRemote
@synthesize alias;
@synthesize URLString;
@synthesize repository;

@synthesize branches;
- (NSArray*) branches
{
  if (!branches)
  {
    NSMutableArray* list = [NSMutableArray array];
    NSURL* aurl = [self.repository gitURLWithSuffix:[@"refs/remotes" stringByAppendingPathComponent:self.alias]];
    for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
    {
      if ([[NSFileManager defaultManager] isReadableFileAtPath:aURL.path])
      {
        NSString* name = [[aURL pathComponents] lastObject];
        if (![name isEqualToString:@"HEAD"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.name = name;
          [list addObject:ref];
        }
      }
    }
    self.branches = list;
  }
  return [[branches retain] autorelease];
}

- (void) dealloc
{
  self.alias = nil;
  self.URLString = nil;
  self.branches = nil;
  [super dealloc];
}
@end
