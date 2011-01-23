#import "GBCloningRepositoryController.h"
#import "GBCloneTask.h"

@interface GBCloningRepositoryController ()
@property(nonatomic,retain) GBCloneTask* task;
@end

@implementation GBCloningRepositoryController

@synthesize sourceURL;
@synthesize targetURL;
@synthesize task;
@synthesize error;

@synthesize delegate;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.task      = nil;
  self.error     = nil;
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
  [super start];
  GBCloneTask* t = [[GBCloneTask new] autorelease];
  self.isDisabled++;
  self.isSpinning++;
  t.sourceURL = self.sourceURL;
  t.targetURL = self.targetURL;
  self.task = t;
  [t launchWithBlock:^{
    self.isSpinning--;
    self.task = nil;
    if ([t isError])
    {
      self.error = [NSError errorWithDomain:@"Gitbox"
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [t UTF8OutputStripped], NSLocalizedDescriptionKey,
                                             [NSNumber numberWithInt:[t terminationStatus]], @"terminationStatus",
                                             [t command], @"command",
                                             nil
                                            ]];
    }
    
    if (t.isTerminated || [t isError])
    {
      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
      NSLog(@"GBCloningRepositoryController: output: %@", [t UTF8OutputStripped]);
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
  }];
}

- (void) stop
{
  if (self.task)
  {
    self.isSpinning--;
    [self.task terminate];
    self.task = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.targetURL error:NULL];
  }
  [super stop];
}

- (void) cancelCloning
{
  [self stop];
  if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidCancel:)]) {
    [self.delegate cloningRepositoryControllerDidCancel:self];
  }  
}

- (void) didSelect
{
  [super didSelect];
  if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidSelect:)]) { 
    [self.delegate cloningRepositoryControllerDidSelect:self];
  }
}

@end
