#import "GBModels.h"
#import "GBTask.h"

#import "NSData+OADataHelpers.h"


@implementation GBTask

@synthesize repository;

+ (id) taskWithRepository:(GBRepository*)repo
{
  GBTask* task = [self task];
  task.repository = repo;
  return task;
}

+ (NSString*) pathToBundledBinary:(NSString*)name
{
  NSBundle* gitBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"git" ofType:@"bundle"]];
  NSString* pathToBinary = [gitBundle pathForResource:name ofType:nil inDirectory:@"libexec/git-core"];
  return pathToBinary;
}

- (NSString*) executableName
{
  return @"git";
}

- (NSString*) launchPath
{
  return [GBTask pathToBundledBinary:@"git"];
}

- (NSString*) currentDirectoryPath
{
  return self.repository.path;
}

- (void) prepareTask
{
  [super prepareTask];
  if (!self.repository)
  {
    NSException *exception = [NSException exceptionWithName:@"RepositoryIsNil"
                                                     reason:@"You may use GBRepository#task to prepare GBTask"  userInfo:nil];
    @throw exception;
  }
}

- (void) dealloc
{
  [super dealloc];
}

@end
