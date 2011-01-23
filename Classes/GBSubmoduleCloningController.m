#import "GBSubmoduleCloningController.h"
#import "GBSubmodule.h"
#import "GBRepository.h"

@implementation GBSubmoduleCloningController

@synthesize error;

@synthesize submodule;
@synthesize delegate;

- (void) dealloc
{
  self.error = nil;
  [super dealloc];
}


#pragma mark GBBaseRepositoryController

- (NSURL*) windowRepresentedURL
{
  return [self.submodule localURL];
}

- (NSURL*) url
{
  return [self.submodule localURL];
}

- (NSString*) windowTitle
{
  return [NSString stringWithFormat:@"%@ — %@", self.submodule.path, [self.submodule.repository.path lastPathComponent]];
}




#pragma mark API


- (void) start
{
  [super start];
  
//  [super start];
//  GBCloneTask* task = [[GBCloneTask new] autorelease];
//  self.isDisabled++;
//  self.isSpinning++;
//  task.sourceURL = self.sourceURL;
//  task.targetURL = self.targetURL;
//  self.cloneTask = task;
//  [task launchWithBlock:^{
//    self.isSpinning--;
//    self.cloneTask = nil;
//    if ([task isError])
//    {
//      self.error = [NSError errorWithDomain:@"Gitbox"
//                                       code:1 
//                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
//                                             [task UTF8OutputStripped], NSLocalizedDescriptionKey,
//                                             [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
//                                             [task command], @"command",
//                                             nil
//                                             ]];
//    }
//    
//    if (task.isTerminated || [task isError])
//    {
//      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
//      NSLog(@"GBCloningRepositoryController: output: %@", [task UTF8OutputStripped]);
//      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFail:)]) {
//        [self.delegate cloningRepositoryControllerDidFail:self];
//      }
//    }
//    else
//    {
//      NSLog(@"GBCloningRepositoryController: did finish clone at %@", self.targetURL);
//			
//      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFinish:)]) {
//        [self.delegate cloningRepositoryControllerDidFinish:self];
//      }
//    }
//  }];
}

- (void) stop
{
//  if (self.cloneTask)
//  {
//    self.isSpinning--;
//    [self.cloneTask terminate];
//    self.cloneTask = nil;
//    [[NSFileManager defaultManager] removeItemAtURL:self.targetURL error:NULL];
//  }
  [super stop];
}

- (void) cancelCloning
{
  [self stop];
//  if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidCancel:)]) {
//    [self.delegate cloningRepositoryControllerDidCancel:self];
//  }  
}

- (void) didSelect
{
  [super didSelect];
//  if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidSelect:)]) { 
//    [self.delegate cloningRepositoryControllerDidSelect:self];
//  }
}



@end
