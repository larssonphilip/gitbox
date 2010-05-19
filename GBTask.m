#import "GBRepository.h"
#import "GBTask.h"

#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBTask

@synthesize repository;

+ (NSString*) absoluteGitPath
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSArray* gitPaths = [NSArray arrayWithObjects:
                       @"~/bin/git",
                       @"/usr/local/bin/git",
                       @"/usr/bin/git",
                       @"/opt/local/bin/git",
                       @"/opt/bin/git",
                       @"/bin/git",
                       nil];
  for (NSString* path in gitPaths)
  {
    if ([fm isExecutableFileAtPath:path])
    {
      return path;
    }
  }
  
  [NSAlert message:@"Couldn't find git executable" 
       description:@"Please install git in a well-known location (such as /usr/local/bin)."];
  [NSApp terminate:self];
  return nil;
}

- (NSString*) launchPath
{
  if (!launchPath)
  {
    self.launchPath = [[self class] absoluteGitPath];
  }
  return [[launchPath retain] autorelease];
}

- (NSString*) currentDirectoryPath
{
  if (!currentDirectoryPath)
  {
    return self.repository.path;
  }
  return [[currentDirectoryPath retain] autorelease];
}

- (void) dealloc
{
  [super dealloc];
}

@end
