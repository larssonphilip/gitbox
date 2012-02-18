#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"
#import "NSData+OADataHelpers.h"

@interface GBCloneTask ()
@end

@implementation GBCloneTask

@synthesize sourceURLString;
@synthesize targetURL;
@synthesize status;
@synthesize progress;

- (void) dealloc
{
  self.sourceURLString = nil;
  self.targetURL = nil;
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
  NSAssert(self.sourceURLString, @"Source URL string should be present");
  return [NSArray arrayWithObjects:@"clone", self.sourceURLString, folder, @"--progress", nil];
}

@end
