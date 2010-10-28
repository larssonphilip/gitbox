#import "GBCloneTask.h"
#import "GBTask.h"

@implementation GBCloneTask

@synthesize sourceURL;
@synthesize targetURL;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
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

- (void) prepareTask
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  self.arguments = [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, nil];
  [super prepareTask];
}

@end
