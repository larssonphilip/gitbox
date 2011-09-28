// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSFileManager (OAFileManagerHelpers)

#pragma mark Interrogation

+ (BOOL) isReadableDirectoryAtPath:(NSString*)path;
- (BOOL) isReadableDirectoryAtPath:(NSString*)path;

+ (BOOL) isWritableDirectoryAtPath:(NSString*)path;
- (BOOL) isWritableDirectoryAtPath:(NSString*)path;

+ (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url;
- (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url;

+ (void) calculateSizeAtURL:(NSURL*)aURL completionHandler:(void(^)())completionHandler;

#pragma mark Mutation

- (void) createFolderForPath:(NSString*)path;
- (void) createFolderForFilePath:(NSString*)path;
- (void) writeData:(NSData*)data toPath:(NSString*)path;

@end
