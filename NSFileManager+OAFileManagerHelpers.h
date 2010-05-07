
@interface NSFileManager (OAFileManagerHelpers)

+ (BOOL) isReadableDirectoryAtPath:(NSString*)path;
- (BOOL) isReadableDirectoryAtPath:(NSString*)path;
+ (BOOL) isWritableDirectoryAtPath:(NSString*)path;
- (BOOL) isWritableDirectoryAtPath:(NSString*)path;

@end
