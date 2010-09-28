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

- (NSString*) executableName
{
  return @"git";
}

- (NSString*) launchPath
{
  NSBundle* gitBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"git-1.7.1" ofType:@"bundle"]];
  NSString* pathToGitBinary = [gitBundle pathForResource:@"git" ofType:nil inDirectory:@"bin"];
  return pathToGitBinary;
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
