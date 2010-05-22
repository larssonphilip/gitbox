// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSFileManager (OAFileManagerHelpers)

+ (BOOL) isReadableDirectoryAtPath:(NSString*)path;
- (BOOL) isReadableDirectoryAtPath:(NSString*)path;

+ (BOOL) isWritableDirectoryAtPath:(NSString*)path;
- (BOOL) isWritableDirectoryAtPath:(NSString*)path;

+ (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url;
- (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url;

@end
