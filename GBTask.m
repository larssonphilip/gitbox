#import "GBModels.h"
#import "GBTask.h"

#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBTask

@synthesize repository;

- (NSString*) executableName
{
  return @"git";
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
