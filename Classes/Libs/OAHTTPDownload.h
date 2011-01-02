// OAHTTPDownload acts as a thin wrapper for NSURLConnection.
// It mirrors all NSURLConnection delegate methods with the OAHTTPDownload* methods.
// If you implement a delegate method you should send to download object
// its non-prefixed method to let it provide default implementation. 
// You may avoid doing that to provide completely different behavior.
// 
// Example: implement OAHTTPDownload:didReceiveData: and do not send [aDownload didReceiveData:data] in order to
//          prevent aDownload from collecting the data.

#import "OAHTTPDownloadDelegate.h"

extern NSInteger const OAHTTPDownloadErrorCodeContentType;
extern NSString* const OAHTTPDownloadErrorDomain;
extern NSString* const OAHTTPDownloadHTTPCodeErrorDomain;

@interface OAHTTPDownload : NSObject <NSCoding>

@property(nonatomic,retain) NSURLRequest*  request;
@property(nonatomic,copy)   NSURL*         url;
@property(nonatomic,copy)   NSString*      username;
@property(nonatomic,copy)   NSString*      password;
@property(nonatomic,copy)   NSArray*       allowedContentTypes;
@property(nonatomic,retain) NSURLConnection* connection;
@property(nonatomic,retain) NSData* data;
@property(nonatomic,retain) NSHTTPURLResponse* lastResponse;
@property(nonatomic,retain) NSError* error;
@property(nonatomic,copy)   void(^block)();
@property(nonatomic,copy)   void(^completionBlock)();
@property(nonatomic,copy)   NSString* runLoopMode;
@property(nonatomic,copy)   NSURL* targetFileURL;
@property(nonatomic,retain) NSMutableDictionary* userDictionary;

@property(nonatomic,assign) NSUInteger byteOffset;
@property(nonatomic,assign) BOOL doNotShowActivityIndicator;
@property(nonatomic,assign) NSObject<OAHTTPDownloadDelegate>* delegate;
@property(nonatomic,assign) BOOL alreadyStarted;

+ (id) download;
+ (id) downloadWithURL:(NSURL*)url;
+ (id) downloadWithRequest:(NSURLRequest*)request;
+ (id) downloadWithURL:(NSURL*)url delegate:(NSObject<OAHTTPDownloadDelegate>*)delegate;
+ (id) downloadWithRequest:(NSURLRequest*)request delegate:(NSObject<OAHTTPDownloadDelegate>*)delegate;

- (id) objectForKey:(NSString*)aKey;
- (void) setObject:(id)obj forKey:(NSString*)aKey;

- (void) start;
- (void) startWithBlock:(void(^)())aBlock;
- (void) cancel;
- (BOOL) isCancelled;
- (float) loadingProgress;

// Common callbacks
- (void) didFinishLoading;
- (void) didFailWithError:(NSError*)error;
- (void) didComplete; // sent when either failed or finished successfully; calls self.block

// Not so common callbacks
- (NSURLRequest*) willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response;
- (NSInputStream*) needNewBodyStream:(NSURLRequest*)request;
- (BOOL) canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace;
- (void) didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (void) didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (BOOL) shouldUseCredentialStorage;
- (void) didReceiveResponse:(NSURLResponse*)response;
- (void) didReceiveData:(NSData*)data;
- (void) didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
- (NSCachedURLResponse*) willCacheResponse:(NSCachedURLResponse*)cachedResponse;

@end
