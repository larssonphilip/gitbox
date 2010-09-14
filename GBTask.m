#import "GBModels.h"
#import "GBTask.h"

#import "NSData+OADataHelpers.h"


@implementation GBTask

@synthesize repository;

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

- (void) dealloc
{
  [super dealloc];
}

@end
