#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"


@implementation GBSubmodule

@synthesize remoteURL;
@synthesize path;
@synthesize repository;


#pragma mark Object lifecycle

- (void) dealloc
{
  self.remoteURL = nil;
  self.path      = nil;
}



#pragma mark Interrogation

- (NSURL*) localURL
{
  return [NSURL URLWithString:[self path] relativeToURL:[[self repository] url]];
}

- (NSString*) localPath
{
  return [[self localURL] path];
}

- (NSURL*) repositoryURL
{
  return [[self repository] url];
}

- (NSString*) repositoryPath
{
  return [[self repositoryURL] path];
}



#pragma mark Mutation

- (void) pullWithBlock:(void(^)())block
{
  OATask* task = [OATask task];

  task.currentDirectoryPath = [self repositoryPath];

  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  
  
  task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", [self localPath], nil];
  
  [task launchWithBlock:block];
}

@end
