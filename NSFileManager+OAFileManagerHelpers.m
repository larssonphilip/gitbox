#import "NSFileManager+OAFileManagerHelpers.h"

@implementation NSFileManager (OAFileManagerHelpers)

+ (BOOL) isReadableDirectoryAtPath:(NSString*)path
{
  return [[self defaultManager] isReadableDirectoryAtPath:path];
}

- (BOOL) isReadableDirectoryAtPath:(NSString*)path
{
  BOOL isDirectory = NO;
  if ([self isReadableFileAtPath:path] && [self fileExistsAtPath:path isDirectory:&isDirectory])
  {
    return isDirectory;
  }
  return NO;
}

+ (BOOL) isWritableDirectoryAtPath:(NSString*)path
{
  return [[self defaultManager] isWritableDirectoryAtPath:path];
}

- (BOOL) isWritableDirectoryAtPath:(NSString*)path
{
  BOOL isDirectory = NO;
  if ([self isWritableFileAtPath:path] && [self fileExistsAtPath:path isDirectory:&isDirectory])
  {
    return isDirectory;
  }
  return NO;
}

@end
