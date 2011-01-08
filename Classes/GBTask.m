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
  NSString* pathToPlaceholder = [[NSBundle mainBundle] pathForResource:@"git-placeholder" ofType:@"bundle"];
  NSAssert(!!pathToPlaceholder, @"ERROR: pathToPlaceholder is nil!");
  
  NSString* pathToBundle = [pathToPlaceholder stringByReplacingOccurrencesOfString:@"-placeholder" withString:@""];
  if (![[NSFileManager defaultManager] fileExistsAtPath:pathToBundle])
  {
    pathToBundle = nil;
  }
  if (!pathToBundle)
  {
    NSString* pathToTar = [[NSBundle mainBundle] pathForResource:@"git.bundle" ofType:@"tar"];
    if (!pathToTar)
    {
      NSLog(@"ERROR: Missing git.bundle.tar in the application package!");
    }
    
    NSAssert(!!pathToTar, @"Missing git.bundle.tar in the application package!");    
    
    OATask* unpackTask = [OATask task];
    unpackTask.executableName = @"tar";
    unpackTask.arguments = [NSArray arrayWithObjects:@"-xf", pathToTar, nil];
    unpackTask.currentDirectoryPath = [pathToTar stringByDeletingLastPathComponent];
    [unpackTask launchAndWait];
    
#if DEBUG
    // Do not remove tar to avoid creation of it again on every run
#else
    [[NSFileManager defaultManager] removeItemAtPath:pathToTar error:NULL];
#endif
    // Note: asking nsbundle for the path again won't work: needs some time
    //pathToBundle = [[NSBundle mainBundle] pathForResource:@"git" ofType:@"bundle"];
    pathToBundle = [pathToPlaceholder stringByReplacingOccurrencesOfString:@"-placeholder" withString:@""];
  }
  if (!pathToBundle)
  {
    NSLog(@"ERROR: Missing git.bundle in the application package!");
  }

  NSAssert(!!pathToBundle, @"Missing git.bundle in the application package!");
  
  NSBundle* gitBundle = [NSBundle bundleWithPath:pathToBundle];
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
  return [self.repository.url path];
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

@end
