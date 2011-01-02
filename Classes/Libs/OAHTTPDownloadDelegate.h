@class OAHTTPDownload;
@protocol OAHTTPDownloadDelegate
@optional
- (NSURLRequest*) OAHTTPDownload:(OAHTTPDownload*)aDownload willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response;
- (NSInputStream*) OAHTTPDownload:(OAHTTPDownload*)aDownload needNewBodyStream:(NSURLRequest*)request;
- (BOOL) OAHTTPDownload:(OAHTTPDownload*)aDownload canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (BOOL) OAHTTPDownloadShouldUseCredentialStorage:(OAHTTPDownload*)aDownload;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didReceiveResponse:(NSURLResponse*)response;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didReceiveData:(NSData*)data;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
- (void) OAHTTPDownloadDidFinishLoading:(OAHTTPDownload*)aDownload;
- (void) OAHTTPDownload:(OAHTTPDownload*)aDownload didFailWithError:(NSError*)error;
- (void) OAHTTPDownloadDidComplete:(OAHTTPDownload*)aDownload; // called after fail or finish
- (NSCachedURLResponse*) OAHTTPDownload:(OAHTTPDownload*)aDownload willCacheResponse:(NSCachedURLResponse*)cachedResponse;
@end
