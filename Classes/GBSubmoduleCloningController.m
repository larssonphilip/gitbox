#import "GBTask.h"
#import "GBSubmoduleCloningController.h"
#import "GBSubmodule.h"
#import "GBRepository.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBSubmoduleCloningController ()
@property(nonatomic, retain) GBTask* task;
@end

@implementation GBSubmoduleCloningController

@synthesize error;
@synthesize task;

@synthesize submodule;

- (void) dealloc
{
  self.error = nil;
  self.task = nil;
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


- (BOOL) isDownloading
{
  return !!self.task;
}


- (void) start
{
  if (self.task) return;

//  self.isDisabled++;
//  self.isSpinning++;

  self.task = [self.submodule.repository task];
  self.task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--", self.submodule.path, nil];
  
  [self.task launchWithBlock:^{
//    self.isDisabled--;
//    self.isSpinning--;
    GBTask* aTask = self.task;
    self.task = nil;
    if ([aTask isError])
    {
      self.error = [NSError errorWithDomain:@"Gitbox"
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [aTask UTF8ErrorAndOutput], NSLocalizedDescriptionKey,
                                             [NSNumber numberWithInt:[aTask terminationStatus]], @"terminationStatus",
                                             [aTask command], @"command",
                                             nil
                                             ]];
    }
    
    if ([aTask isError])
    {
      NSLog(@"GBSubmoduleCloningController: did FAIL to clone at %@", [self.submodule localURL]);
      NSLog(@"GBSubmoduleCloningController: output: %@", [aTask UTF8ErrorAndOutput]);
      [self notifyWithSelector:@selector(submoduleCloningControllerDidFail:)];
    }
    else
    {
      NSLog(@"GBSubmoduleCloningController: did finish clone at %@", [self.submodule localURL]);
			[self notifyWithSelector:@selector(submoduleCloningControllerDidFinish:)];
    }
  }];

  [self notifyWithSelector:@selector(submoduleCloningControllerDidStart:)];
}

- (void) stop
{
  if (self.task)
  {
//    self.isSpinning--;
    [self.task terminate];
    self.task = nil;
    NSURL* dotgitURL = [NSURL URLWithString:[[[self.submodule localURL] path] stringByAppendingPathComponent:@".git"]];
    [[NSFileManager defaultManager] removeItemAtURL:dotgitURL error:NULL];
  }
}

- (void) cancelCloning
{
  [self stop];
  [self notifyWithSelector:@selector(submoduleCloningControllerDidCancel:)];
}

- (void) didSelectWindowItem
{
  [self notifyWithSelector:@selector(submoduleCloningControllerDidSelect:)];
}



@end
