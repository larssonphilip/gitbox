#import "GBRemote.h"

@implementation GBRemote
@synthesize alias;
@synthesize URLString;
@synthesize branches;

- (NSArray*) branches
{
  if (!branches)
  {
    
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
