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

+ (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url
{
  return [[self defaultManager] contentsOfDirectoryAtURL:url];
}

- (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url
{
  if (!url)
  {
    NSLog(@"WARNING: NSFileManager: url is nil; returning empty array");
    return [NSArray array];
  }
  NSError* outError = nil; 
  NSArray* URLs = [[NSFileManager defaultManager] 
                   contentsOfDirectoryAtURL:url
                   includingPropertiesForKeys:[NSArray array] 
                   options:0 
                   error:&outError];
  if (!URLs)
  {
    NSLog(@"ERROR: NSFileManager: %@", [outError localizedDescription]);
    return [NSArray array];
  }
  return URLs;
}

@end
