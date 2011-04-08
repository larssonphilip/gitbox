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

- (NSArray*) arguments
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  NSAssert(folder, [NSString stringWithFormat:@"Target URL should have last path component (self.targetURL = %@)", self.targetURL]);
  NSAssert(self.sourceURL, @"Source URL should be present");
  return [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, nil];
}

@end
