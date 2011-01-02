#import "GBCloningRepositoryController.h"
#import "GBCloneTask.h"
#import "GBSubmoduleInitTask.h"
#import "NSData+OADataHelpers.h"

@implementation GBCloningRepositoryController

@synthesize sourceURL;
@synthesize targetURL;
@synthesize cloneTask;
@synthesize error;

@synthesize delegate;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.cloneTask = nil;
  self.error = nil;
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
  GBCloneTask* task = [[GBCloneTask new] autorelease];
  self.isDisabled++;
  self.isSpinning++;
  task.sourceURL = self.sourceURL;
  task.targetURL = self.targetURL;
  self.cloneTask = task;
  [task launchWithBlock:^{
    self.isSpinning--;
    self.cloneTask = nil;
    if ([task isError])
    {
      self.error = [NSError errorWithDomain:@"Gitbox"
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [task.output UTF8String], NSLocalizedDescriptionKey,
                                             [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
                                             [task command], @"command",
                                             nil
                                            ]];
    }
    
    if (task.isTerminated || [task isError])
    {
      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
      NSLog(@"GBCloningRepositoryController: output: %@", [task.output UTF8String]);
      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFail:)]) {
        [self.delegate cloningRepositoryControllerDidFail:self];
      }
    }
    else
    {
      NSLog(@"GBCloningRepositoryController: did finish clone at %@", self.targetURL);

			[self afterSuccessfulClone];
			
      if ([self.delegate respondsToSelector:@selector(cloningRepositoryControllerDidFinish:)]) {
        [self.delegate cloningRepositoryControllerDidFinish:self];
      }
    }
  }];
}

- (void) stop
{
  if (self.cloneTask)
  {
    self.isSpinning--;
    [self.cloneTask terminate];
    self.cloneTask = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.targetURL error:NULL];
  }
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


- (void) afterSuccessfulClone
{
	GBSubmoduleInitTask* task = [[GBSubmoduleInitTask new] autorelease];
	task.targetURL = self.targetURL;
	
	[task launchWithBlock:^{
		if ([task isError]) {
			self.error = [NSError errorWithDomain:@"Gitbox" code:1
																	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						 [task.output UTF8String], NSLocalizedDescriptionKey,
																						 [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
																						 [task command], @"command",
																						 nil]];
		} else {
			NSLog(@"GBCloningRepositoryController: did finish submodule init at %@", self.targetURL);
		}		
	}];
}

@end
