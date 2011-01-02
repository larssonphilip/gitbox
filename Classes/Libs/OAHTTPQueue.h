@class OAHTTPDownload;
@interface OAHTTPQueue : NSObject
@property(nonatomic) NSUInteger maxConcurrentOperationCount; // 1 by default
@property(nonatomic) BOOL coalesceURLs;
@property(nonatomic) NSUInteger limit;
@property(nonatomic, readonly) NSUInteger operationCount;

- (void) addDownload:(OAHTTPDownload*)aDownload;
- (void) cancel;
- (void) enumerateDownloadsUsingBlock:(void(^)(OAHTTPDownload*,BOOL*))block;

@end
