#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"
#import "NSData+OADataHelpers.h"

@implementation GBCloneTask

@synthesize sourceURL;
@synthesize targetURL;
@synthesize progressUpdateBlock;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.progressUpdateBlock = nil;
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

- (NSString*) keychainPasswordName
{
  return [GBRemote keychainPasswordNameForURLString:[self.sourceURL absoluteString]];
}

- (BOOL) isRealTime
{
  return YES;
}

- (NSArray*) arguments
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  NSAssert(folder, ([NSString stringWithFormat:@"Target URL should have last path component (self.targetURL = %@)", self.targetURL]));
  NSAssert(self.sourceURL, @"Source URL should be present");
  return [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, @"--progress", nil];
}

- (void) callProgressBlockWithProgress:(double)pr
{
  if (self.progressUpdateBlock)
  {
    void(^aBlock)(double) = self.progressUpdateBlock;
    dispatch_async(dispatch_get_main_queue(), ^{
      aBlock(pr);
    });
  }
}

- (void) didReceiveStandardOutputData:(NSData*)dataChunk
{
  double progress = 60.0;
  [self callProgressBlockWithProgress:progress];
}

- (void) didFinishInBackground
{
  [self callProgressBlockWithProgress:100.0];
  self.progressUpdateBlock = nil; // break retain cycle through the block
}

@end
