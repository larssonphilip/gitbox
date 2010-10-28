#import "GBCloningRepositoryController.h"
#import "GBCloneTask.h"

@implementation GBCloningRepositoryController

@synthesize sourceURL;
@synthesize targetURL;
@synthesize cloneTask;

@synthesize delegate;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.cloneTask = nil;
  [super dealloc];
}

- (NSURL*) windowRepresentedURL
{
  return self.targetURL;
}

- (NSURL*) url
{
  return self.targetURL;
}

- (void) start
{
  self.cloneTask = [[GBCloneTask new] autorelease];
  self.cloneTask.sourceURL = self.sourceURL;
  self.cloneTask.targetURL = self.targetURL;
  [self.cloneTask launchWithBlock:^{
    [self.cloneTask showErrorIfNeeded];
    if (self.cloneTask.isTerminated || [self.cloneTask isError])
    {
      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFail:)]) {
        [self.delegate cloningRepositoryControllerDidFail:self];
      }
    }
    else
    {
      NSLog(@"GBCloningRepositoryController: did finish clone at %@", self.targetURL);
      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFinish:)]) {
        [self.delegate cloningRepositoryControllerDidFinish:self];
      }
    }
    self.cloneTask = nil;
  }];
}

- (void) stop
{
  [self.cloneTask terminate];
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
