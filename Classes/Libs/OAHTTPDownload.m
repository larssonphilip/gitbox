#import "OAHTTPDownload.h"

// This is to setup usage of one of the objects: OANetworkActivityIndicator or PNetworkActivityStack
#if !defined(OAHTTPDownloadNetworkActivityStack)
	//#import "OANetworkActivityIndicator.h"
	#define OAHTTPDownloadNetworkActivityStack (id)nil
#endif

NSInteger const OAHTTPDownloadErrorCodeContentType = 100;
NSString* const OAHTTPDownloadErrorDomain = @"com.oleganza.OAHTTPDownloadErrorDomain";
NSString* const OAHTTPDownloadHTTPCodeErrorDomain = @"com.oleganza.OAHTTPDownloadErrorDomain.HTTP";

@interface OAHTTPDownload () <NSURLConnectionDelegate>
@property(nonatomic,retain) NSMutableData* receivedData;
@property(nonatomic,retain) NSFileHandle* fileHandleForWriting;
- (void) log:(NSString*)msg;
- (void) logError:(NSError*)error;
- (void) prepareFileHandleIfNeeded;
- (void) resetFileHandle;
@end


@implementation OAHTTPDownload



#pragma mark Factory


+ (id) download
{
	return [[self new] autorelease];
}

+ (id) downloadWithURL:(NSURL*)url
{
	return [self downloadWithURL:url delegate:nil];
}

+ (id) downloadWithRequest:(NSURLRequest*)request
{
	return [self downloadWithRequest:request delegate:nil];
}

+ (id) downloadWithURL:(NSURL*)url delegate:(NSObject<OAHTTPDownloadDelegate>*)delegate
{
	OAHTTPDownload* d = [self download];
	d.url = url;
	d.delegate = delegate;
	return d;  
}

+ (id) downloadWithRequest:(NSURLRequest*)request delegate:(NSObject<OAHTTPDownloadDelegate>*)delegate
{
	OAHTTPDownload* d = [self download];
	d.request = request;
	d.delegate = delegate;
	return d;
}





#pragma mark Memory


@synthesize request;
@synthesize url;
@synthesize username;
@synthesize password;
@synthesize allowedContentTypes;
@synthesize connection;
@synthesize data;
@synthesize lastResponse;
@synthesize error;
@synthesize block;
@synthesize completionBlock;
@synthesize runLoopMode;
@synthesize targetFileURL;
@synthesize receivedData;
@synthesize fileHandleForWriting;
@synthesize userDictionary;

@synthesize byteOffset;
@synthesize doNotShowActivityIndicator;
@synthesize delegate;
@synthesize alreadyStarted;

- (void) dealloc
{
	self.request = nil;
	self.url = nil;
	self.username = nil;
	self.password = nil;
  self.allowedContentTypes = nil;
	self.connection = nil;
	self.receivedData = nil;
	self.data = nil;
	self.lastResponse = nil;
	self.error = nil;
	self.block = nil;
	self.completionBlock = nil;
	self.runLoopMode = nil;
	self.targetFileURL = nil;
	self.fileHandleForWriting = nil;
	self.userDictionary = nil;
	
	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
	//	NSLog(@"%@: init %p", [self class], self);
		self.userDictionary = [NSMutableDictionary dictionary];
	}
	return self;
}



#pragma mark API



- (id) objectForKey:(NSString*)aKey
{
	return [self.userDictionary objectForKey:aKey];
}

- (void) setObject:(id)obj forKey:(NSString*)aKey
{
	[self.userDictionary setObject:obj forKey:aKey];
}

- (void) start
{
  if (!self.request && self.url)
  {
    self.request = [NSURLRequest requestWithURL:self.url];
  }
  if (!self.url) self.url = [self.request URL];

	if (self.targetFileURL)
	{
		[self prepareFileHandleIfNeeded];
	}
	
	if (self.byteOffset > 0)
	{
		NSMutableURLRequest* mutableRequest = [[self.request mutableCopy] autorelease];
		[mutableRequest setValue:[NSString stringWithFormat:@"bytes=%u-", self.byteOffset] forHTTPHeaderField:@"Range"];
		self.request = mutableRequest;
	}
	
  NSAssert(self.request || self.url, @"OAHTTPDownload: either url or request property should be present");
  self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
  if (self.runLoopMode) 
  {
	// NSRunLoopCommonModes includes UITrackingRunLoopMode
	  
	// This mode makes notification happen while user is scrolling
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:self.runLoopMode]; 
  }
  else
  {
	// This mode makes notification happen when user stopped scrolling
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode]; // use default mode if not a modern OS
  }
  [self.connection start];
  self.alreadyStarted = YES;
  if (!self.doNotShowActivityIndicator) [OAHTTPDownloadNetworkActivityStack push];
}

- (void) startWithBlock:(void(^)())aBlock
{
	self.block = [[aBlock copy] autorelease];
	[self start];
}

- (void) cancel
{
  if (self.connection)
  {
    NSURLConnection* c = self.connection;
    self.connection = nil;
    [c cancel];
    [self.fileHandleForWriting closeFile];
    self.fileHandleForWriting = nil;
    if (!self.doNotShowActivityIndicator) [OAHTTPDownloadNetworkActivityStack pop];
  }
  if (self.completionBlock) self.completionBlock();
  self.completionBlock = nil;
}

- (BOOL) isCancelled
{
	return !self.connection;
}

- (float) loadingProgress
{
	NSData* aData = self.receivedData;
	NSHTTPURLResponse* response = self.lastResponse;

	if (aData && response && [response expectedContentLength] != NSURLResponseUnknownLength)
	{
		float contentLength = (float)[response expectedContentLength];
		if (contentLength <= 0) return (float)0.0;
		contentLength += (float)self.byteOffset;
		
		float dataLength = (float)[aData length] + self.byteOffset;
		if (self.fileHandleForWriting)
		{
			dataLength = (float)[self.fileHandleForWriting offsetInFile];
		}
		
		if (contentLength > 0.001)
		{
			return dataLength / contentLength;
		}
	}
	return (float)0.0;
}






#pragma mark OAHTTPDownload implementation



- (NSURLRequest*) willSendRequest:(NSURLRequest*)aRequest redirectResponse:(NSURLResponse*)aResponse
{
  return aRequest;
}

- (NSInputStream*) needNewBodyStream:(NSURLRequest*)aRequest
{
  return NULL;
}

- (BOOL) canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)aProtectionSpace
{
  return NO;
}

// Note: this method does not take advantage of proposedCredential and persistant credentials yet.
// AFAIK, iphone does not support that api yet.
- (void) didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
  if (self.username && self.password)
  {
    NSURLCredential* credential = [NSURLCredential credentialWithUser:self.username 
                                                             password:self.password
                                                          persistence:NSURLCredentialPersistenceNone];
    [[aChallenge sender] useCredential:credential forAuthenticationChallenge:aChallenge];
  }
  else
  {
    [self log:@"received authentication challenge, but username or password is nil; proceeding without credentials"];
    [[aChallenge sender] continueWithoutCredentialForAuthenticationChallenge:aChallenge];
  }  
}

- (void) didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
}

- (BOOL) shouldUseCredentialStorage
{
  return YES;
}

// Note: this method is called once per mime type; it should reset received data appropriately
- (void) didReceiveResponse:(NSURLResponse*)aResponse
{
	self.lastResponse = (NSHTTPURLResponse*)aResponse;
	
	NSDictionary* headers = [self.lastResponse allHeaderFields];

	// deal with a stupid Orange proxy problem (migrated from LIDownloader, ask Fred Sigal what this is)
	NSString* warningHeader = [headers objectForKey:@"Warning"];
	if ([warningHeader length])
	{
		NSLog(@"%@ didReceiveResponse: got Warning header. Cancelling.", [self class]);
		NSError* anError = [NSError errorWithDomain:@"com.oleganza.OAHTTPDownload" code:[self.lastResponse statusCode] userInfo:
							[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[self.lastResponse statusCode]]
														forKey:NSLocalizedDescriptionKey]];
		
		[self connection:self.connection didFailWithError:anError];
		[self cancel];
		return;
	}

  // debug
//  NSString* contentType = [headers objectForKey:@"Content-Type"];
//  [self log:[NSString stringWithFormat:@"didReceiveResponse with content type '%@'", contentType]];

  if (self.allowedContentTypes && [self.allowedContentTypes count] > 0)
  {
    NSString* contentType = [headers objectForKey:@"Content-Type"];
    if (![self.allowedContentTypes containsObject:contentType])
    {
      [self log:[NSString stringWithFormat:@"didReceiveResponse: content type '%@' not in allowedContentTypes = %@", contentType, self.allowedContentTypes]];
      NSError* anError = [NSError errorWithDomain:OAHTTPDownloadErrorDomain code:OAHTTPDownloadErrorCodeContentType userInfo:nil];
      [self connection:self.connection didFailWithError:anError];
      [self cancel];
      return;
    }
  }
	
	if (self.receivedData != nil)
	{
		[self log:@"didReceiveResponse: data is not nil => multipart download detected; resetting data"];
		[self resetFileHandle];
	}
	
	if (![headers objectForKey:@"Accept-Ranges"])
	{
		self.byteOffset = 0;
		[self resetFileHandle];
	}
	
  self.receivedData = [NSMutableData data];
  self.data = self.receivedData;
}

- (void) didReceiveData:(NSData*)aData
{
	if (self.fileHandleForWriting)
	{
		[self.fileHandleForWriting writeData:aData];
	}
	else
	{
	  [self.receivedData appendData:aData];
	}
}

- (void) didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

- (void) didFinishLoading
{
}

- (void) didFailWithError:(NSError*)anError
{
  if ([anError code] != 404)
  {
    NSLog(@"%@ didFailWithError: %@", [self class], anError);
  }
  self.error = anError;
}

- (void) didComplete
{
	//NSLog(@"OAHTTPDownload %p did complete: block = %p", self, (id)self.block);

	if (self.block) self.block();
	if (self.completionBlock) self.completionBlock();
	
	self.data = nil;
	self.receivedData = nil;
	self.block = nil; // this will clear the cycle if the block references this download
	self.completionBlock = nil;
	
	[self.fileHandleForWriting closeFile];
	self.fileHandleForWriting = nil;
}

- (NSCachedURLResponse*) willCacheResponse:(NSCachedURLResponse*)aCachedResponse
{
  return aCachedResponse;
}





#pragma mark NSURLConnection delegate



- (NSURLRequest*) connection:(NSURLConnection*)aConnection willSendRequest:(NSURLRequest*)aRequest redirectResponse:(NSURLResponse*)aRedirectResponse
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:willSendRequest:redirectResponse:)])
    return [self.delegate OAHTTPDownload:self willSendRequest:aRequest redirectResponse:aRedirectResponse];
  else
    return [self willSendRequest:aRequest redirectResponse:aRedirectResponse];
}

- (NSInputStream*) connection:(NSURLConnection*)aConnection needNewBodyStream:(NSURLRequest*)aRequest
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:needNewBodyStream:)])
    return [self.delegate OAHTTPDownload:self needNewBodyStream:aRequest];
  else
    return [self needNewBodyStream:aRequest];  
}

- (BOOL) connection:(NSURLConnection*)aConnection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)aProtectionSpace
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:canAuthenticateAgainstProtectionSpace:)])
    return [self.delegate OAHTTPDownload:self canAuthenticateAgainstProtectionSpace:aProtectionSpace];
  else
    return [self canAuthenticateAgainstProtectionSpace:aProtectionSpace];
}

- (void) connection:(NSURLConnection*)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didReceiveAuthenticationChallenge:)])
    [self.delegate OAHTTPDownload:self didReceiveAuthenticationChallenge:aChallenge];
  else
    [self didReceiveAuthenticationChallenge:aChallenge];
}

- (void) connection:(NSURLConnection*)aConnection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)aChallenge
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didCancelAuthenticationChallenge:)])
    [self.delegate OAHTTPDownload:self didCancelAuthenticationChallenge:aChallenge];
  else
    [self didCancelAuthenticationChallenge:aChallenge];
}

- (BOOL) connectionShouldUseCredentialStorage:(NSURLConnection*)aConnection
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownloadShouldUseCredentialStorage:)])
    return [self.delegate OAHTTPDownloadShouldUseCredentialStorage:self];
  else
    return [self shouldUseCredentialStorage];
}

// Note: this method is called once per mime type; it should reset received data appropriately
- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)aResponse
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didReceiveResponse:)])
    [self.delegate OAHTTPDownload:self didReceiveResponse:aResponse];
  else
    [self didReceiveResponse:aResponse];
}

- (void) connection:(NSURLConnection*)aConnection didReceiveData:(NSData*)aData
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didReceiveData:)])
    [self.delegate OAHTTPDownload:self didReceiveData:aData];
  else
    [self didReceiveData:aData];
}

- (void) connection:(NSURLConnection*)aConnection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)])
    [self.delegate OAHTTPDownload:self didSendBodyData:bytesWritten 
                       totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
  else
    [self didSendBodyData:bytesWritten 
               totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)aConnection
{
  if (self.lastResponse)
  {
    NSInteger code = [self.lastResponse statusCode];
    if (code < 200 || code > 399) // do not report redirection codes as errors
    {
      NSError* anError = [NSError errorWithDomain:OAHTTPDownloadHTTPCodeErrorDomain code:code userInfo:nil];
      [self connection:aConnection didFailWithError:anError];
      return;
    }
  }
  
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownloadDidFinishLoading:)])
    [self.delegate OAHTTPDownloadDidFinishLoading:self];
  else
    [self didFinishLoading];
  
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownloadDidComplete:)])
    [self.delegate OAHTTPDownloadDidComplete:self];
  else
    [self didComplete];

  if (self.connection && !self.doNotShowActivityIndicator) [OAHTTPDownloadNetworkActivityStack pop];
  self.connection = nil;
}

- (void) connection:(NSURLConnection*)aConnection didFailWithError:(NSError*)anError
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:didFailWithError:)])
    [self.delegate OAHTTPDownload:self didFailWithError:anError];
  else
    [self didFailWithError:anError];
  
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownloadDidComplete:)])
    [self.delegate OAHTTPDownloadDidComplete:self];
  else
    [self didComplete];
  if (self.connection && !self.doNotShowActivityIndicator) [OAHTTPDownloadNetworkActivityStack pop];
  self.connection = nil;
}

- (NSCachedURLResponse*) connection:(NSURLConnection*)aConnection willCacheResponse:(NSCachedURLResponse*)aCachedResponse
{
  if ([self.delegate respondsToSelector:@selector(OAHTTPDownload:willCacheResponse:)])
    return [self.delegate OAHTTPDownload:self willCacheResponse:aCachedResponse];
  else
    return [self willCacheResponse:aCachedResponse];  
}





#pragma mark NSCoding



- (id)initWithCoder:(NSCoder*)coder 
{
  self = [super init];
  self.url      = [coder decodeObjectForKey:@"url"];
  self.request  = [coder decodeObjectForKey:@"request"];
  self.username = [coder decodeObjectForKey:@"username"];
  self.password = [coder decodeObjectForKey:@"password"];
  return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
  [coder encodeObject:self.url      forKey:@"url"];
  [coder encodeObject:self.request  forKey:@"request"];
  [coder encodeObject:self.username forKey:@"username"];
  [coder encodeObject:self.password forKey:@"password"];
}





#pragma mark Logging


- (void) log:(NSString*)msg
{
  NSLog(@"OAHTTPDownload: %@ [%@]", msg, [[request URL] absoluteString]);
}

- (void) logError:(NSError*)anError
{
  [self log:[anError localizedDescription]];
}

- (void) prepareFileHandleIfNeeded
{
	if (self.fileHandleForWriting) return;
	
	if (!self.targetFileURL)
	{
		[self log:@"ERROR: targetFileURL is nil!"];
		return;
	}
	
	if (![self.targetFileURL isFileURL])
	{
		[self log:@"ERROR: targetFileURL is not a file URL!"];
		return;
	}
	
	NSString* filePath = [self.targetFileURL path];
	
	if (!filePath)
	{
		[self log:@"ERROR: [targetFileURL path] returned nil!"];
		return;
	}
		
	NSString* directoryPath = [filePath stringByDeletingLastPathComponent];
	NSError* theError = nil;
	NSFileManager* fm = [[NSFileManager new] autorelease];
	if ([fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&theError])
	{
		if (![fm fileExistsAtPath:filePath])
		{
			[fm createFileAtPath:filePath contents:[NSData data] attributes:nil];
		}
		
		NSDictionary* attributes = [fm attributesOfItemAtPath:filePath error:&theError];
		if (attributes)
		{
			self.byteOffset = [attributes fileSize];
		}
		else
		{
			[self logError:theError];
			return;
		}
		
		self.fileHandleForWriting = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[self.fileHandleForWriting seekToEndOfFile]; // works in all cases: either the file is empty, or has some data.
	}
	else
	{
		[self logError:theError];
	}
}

- (void) resetFileHandle
{
	if (!self.fileHandleForWriting) return;
	if (!self.targetFileURL) return;
	
	[self.fileHandleForWriting closeFile];
	self.fileHandleForWriting = nil;

	NSError* theError = nil;
	if (![[NSFileManager defaultManager] removeItemAtURL:self.targetFileURL error:&theError])
	{
		[self logError:theError];
	}
		
	[self prepareFileHandleIfNeeded];
}


@end
