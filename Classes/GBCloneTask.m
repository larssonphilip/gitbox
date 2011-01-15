#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"

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

- (NSString*) keychainPasswordName
{
  return [GBRemote keychainPasswordNameForURLString:[self.sourceURL absoluteString]];
}

- (void) prepareTask
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  self.arguments = [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, nil];
  [super prepareTask];
}

@end
