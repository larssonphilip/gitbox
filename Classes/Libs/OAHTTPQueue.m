#import "OAHTTPQueue.h"
#import "OAHTTPDownload.h"

@interface OAHTTPQueue ()
@property(nonatomic, retain) NSMutableArray* queue;
@property(nonatomic, retain) NSMutableArray* activeDownloads;
@property(nonatomic, assign) BOOL cancelling;
- (void) proceed;
- (void) removeDownload:(OAHTTPDownload*)aDownload;
@end


@implementation OAHTTPQueue

@synthesize queue;
@synthesize activeDownloads;

@synthesize maxConcurrentOperationCount; // 1 by default
@synthesize coalesceURLs;
@synthesize limit;
@synthesize cancelling;
@dynamic operationCount;

- (id) init
{
	if ((self = [super init]))
	{
		self.queue = [NSMutableArray arrayWithCapacity:32];
		self.activeDownloads = [NSMutableArray arrayWithCapacity:32];
		self.maxConcurrentOperationCount = 1;
		self.limit = 0;
	}
	return self;
}

- (void) dealloc
{
	[self cancel];
	self.queue = nil;
	self.activeDownloads = nil;
	[super dealloc];
}

- (NSUInteger) operationCount
{
	return [self.activeDownloads count];
}


- (void) addDownload:(OAHTTPDownload*)aDownload
{
	NSAssert(!aDownload.alreadyStarted, @"ERROR: OAHTTPQueue: addDownload method expects a non-started download");
	
	if ([self.queue count] > 1)
	{
		NSLog(@"OAHTTPQueue:%p has already %d downloads in a queue (adding %@)", self, (int)[self.queue count], aDownload.url);
	}
	
	if (self.coalesceURLs)
	{
		if ([[self.activeDownloads valueForKey:@"url"] containsObject:aDownload.url])
		{
			//NSLog(@"OAHTTPQueue: coalescing url %@ with an active download.", aDownload.url);
			return;
		}
		if ([[self.queue valueForKey:@"url"] containsObject:aDownload.url])
		{
			//NSLog(@"OAHTTPQueue: coalescing url %@ with a queued download.", aDownload.url);
			return;
		}		
	}
	
	if (self.limit > 0 && [self.queue count] >= self.limit)
	{
		[self.queue removeObjectAtIndex:0];
	}
	
	void(^completionBlock)() = [[aDownload.completionBlock copy] autorelease];
	
	// Note: here we create a cyclic reference: download -> block -> download
	// But it's okay since download object will always release the block when done.
	aDownload.completionBlock = ^{
		//NSLog(@"%@ completed download %@", [self class], aDownload.url);
		if (completionBlock) completionBlock();
		[self removeDownload:aDownload];
	};
	
	[self.queue addObject:aDownload];
	[self proceed];
}

- (void) removeDownload:(OAHTTPDownload*)aDownload
{
	[self.queue removeObject:aDownload];
	[self.activeDownloads removeObject:aDownload];
	[self proceed];
}

- (void) enumerateDownloadsUsingBlock:(void(^)(OAHTTPDownload*, BOOL*))block
{
	if (!block) return;
	BOOL stop = NO;
	for (OAHTTPDownload* aDownload in [NSArray arrayWithArray:self.queue])
	{
		block(aDownload, &stop);
		if (stop) return;
	}
	for (OAHTTPDownload* aDownload in [NSArray arrayWithArray:self.activeDownloads])
	{
		block(aDownload, &stop);
		if (stop) return;
	}	
}


#pragma mark Private



- (void) proceed
{
	if (self.operationCount < self.maxConcurrentOperationCount && !self.cancelling)
	{
		if (self.queue && [self.queue count] > 0)
		{
			OAHTTPDownload* aDownload = [self.queue objectAtIndex:0];
			[self.activeDownloads addObject:aDownload];
			[self.queue removeObject:aDownload];
			
			NSAssert(!aDownload.alreadyStarted, @"ERROR: OAHTTPQueue expects a non-started download in a queue");
			//NSLog(@"%@ starting download %@ [%d / %d]", [self class], aDownload.url, self.operationCount, self.maxConcurrentOperationCount);
			[aDownload start];
		}
	}
}

- (void) cancel
{
	//NSLog(@"OAHTTPQueue: cancelling...");
	self.cancelling = YES;
	NSUInteger a = [self.activeDownloads count];
	NSUInteger q = [self.queue count];

	[self enumerateDownloadsUsingBlock:^(OAHTTPDownload* aDownload, BOOL* stop){
		[aDownload cancel];
	}];
	
	if (a + q > 0)
	{
		NSLog(@"OAHTTPQueue: cancelled %d active and %d queued downloads.", (int)a, (int)q);
	}
	[self.queue removeAllObjects];
	[self.activeDownloads removeAllObjects];
	self.cancelling = NO;
}

@end
