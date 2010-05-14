#import "GBChange.h"

@implementation GBChange

@synthesize url;
@synthesize status;
@synthesize oldRevision;
@synthesize newRevision;
@synthesize staged;

- (void) dealloc
{
  self.url = nil;
  self.status = nil;
  self.oldRevision = nil;
  self.newRevision = nil;
  [super dealloc];
}

@end
