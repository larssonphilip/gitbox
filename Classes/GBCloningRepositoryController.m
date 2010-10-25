#import "GBCloningRepositoryController.h"

@implementation GBCloningRepositoryController

@synthesize sourceURL;
@synthesize url;

@synthesize delegate;

- (void) dealloc
{
  self.sourceURL = nil;
  self.url = nil;
  [super dealloc];
}

- (NSURL*) windowRepresentedURL
{
  return self.url;
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

- (void) didSelect
{
  [super didSelect];
  if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidSelect:)]) { 
    [self.delegate cloningRepositoryControllerDidSelect:self];
  }
}


@end
