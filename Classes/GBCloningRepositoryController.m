#import "GBCloningRepositoryController.h"

@implementation GBCloningRepositoryController

@synthesize sourceURL;
@synthesize url;

- (void) dealloc
{
  self.sourceURL = nil;
  self.url = nil;
  [super dealloc];
}

- (void) start
{
  
//  NSLog(@"TODO: begin clone: %@", self.url);
//  NSLog(@"TODO: when done, remove self from local repositories and add the proper controller");
}

- (void) stop
{
  // repo removed from list: may cancel cloning or clean up after finishing
}

@end
