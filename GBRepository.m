#import "GBRepository.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBRepository

+ (BOOL) isValidRepositoryAtPath:(NSString*) path
{
  return path && [NSFileManager isWritableDirectoryAtPath:[path stringByAppendingPathComponent:@".git"]];
}


@synthesize path;


- (void) dealloc
{
  self.path = nil;
  [super dealloc];
}

@end
