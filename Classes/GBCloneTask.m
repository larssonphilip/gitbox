#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"
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

- (BOOL) ignoreMissingRepository
{
	return YES;
}

- (NSString*) currentDirectoryPath
{
  return [[self.targetURL path] stringByDeletingLastPathComponent];
}

- (NSArray*) arguments
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  NSAssert(folder, @"Target URL should have last path component (self.targetURL = %@)", self.targetURL);
  NSAssert(self.sourceURL, @"Source URL should be present");
  return [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, @"--progress", nil];
}

@end
