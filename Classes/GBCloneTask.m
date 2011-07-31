#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"
#import "GBTaskWithProgress.h"
#import "NSData+OADataHelpers.h"

@interface GBCloneTask ()
@end

@implementation GBCloneTask

@synthesize sourceURL;
@synthesize targetURL;
@synthesize progressUpdateBlock;
@synthesize status;
@synthesize progress;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.progressUpdateBlock = nil;
  self.status = nil;
  [super dealloc];
}

- (NSString*) launchPath
{
  return [GBTask pathToBundledBinary:@"git"];
}

- (NSString*) currentDirectoryPath
{
  return [[self.targetURL path] stringByDeletingLastPathComponent];
}

- (BOOL) isRealTime
{
  return YES;
}

- (NSArray*) arguments
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  NSAssert(folder, @"Target URL should have last path component (self.targetURL = %@)", self.targetURL);
  NSAssert(self.sourceURL, @"Source URL should be present");
  return [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, @"--progress", nil];
}

- (void) callProgressBlock
{
	dispatch_async(dispatch_get_main_queue(), ^{ if (self.progressUpdateBlock) self.progressUpdateBlock(); });
}

- (void) didReceiveStandardErrorData:(NSData*)dataChunk
{
  NSString* newStatus = self.status;
  
  double newProgress = [GBTaskWithProgress progressForDataChunk:dataChunk statusRef:&newStatus];
  if (newProgress <= 0) newProgress = self.progress;
  self.status = newStatus;
  
  // To avoid heavy load on main thread, call the block only when progress changes by 0.5%.
  if (round(newProgress*2) == round(self.progress*2)) return;
  
  self.progress = newProgress;
  [self callProgressBlock];
}

- (void) didFinishInBackground
{
  self.progress = 100.0;
  self.status = @"";
  
  [self callProgressBlock];
  self.progressUpdateBlock = nil; // break retain cycle through the block
}

@end
