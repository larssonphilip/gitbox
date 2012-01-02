#import "GBPeriodicalUpdater.h"
#import "OABlockOperations.h"

@interface GBPeriodicalUpdater ()
@property(nonatomic, copy) void(^updateBlock)();
@property(nonatomic, copy) void(^callback)();
@property(nonatomic, retain) NSDate* lastUpdateDate;
@property(nonatomic, retain) NSDate* nextUpdateDate;
@end

@implementation GBPeriodicalUpdater {
	BOOL updatedOnce;
	NSTimeInterval delayInterval;
	int needsUpdateGeneration;
	BOOL inProgress;
	BOOL needsUpdateWhileWasInProgress;
}

@synthesize updateBlock;
@synthesize initialDelay;
@synthesize maximumDelay;
@synthesize delayMultiplier;
@synthesize callback=_callback;
@synthesize lastUpdateDate;
@synthesize nextUpdateDate;

- (void) dealloc
{
	[updateBlock release];
	[_callback release];
	[lastUpdateDate release];
	[nextUpdateDate release];
	[super dealloc];
}

- (id) init
{
	if (self = [super init])
	{
		initialDelay = 1.0;
		maximumDelay = 24*60*60;
		delayMultiplier = 2.0;
		delayInterval = initialDelay;
	}
	return self;
}

+ (GBPeriodicalUpdater*) updaterWithBlock:(void(^)())block
{
	GBPeriodicalUpdater* u = [[[self alloc] init] autorelease];
	u.updateBlock = block;
	return u;
}

- (NSTimeInterval) timeSinceLastUpdate
{
	if (!self.lastUpdateDate) return 999999.0;
	
	return -[self.lastUpdateDate timeIntervalSinceNow];
}

- (NSTimeInterval) timeUntilNextUpdate
{
	if (!self.nextUpdateDate) return 999999.0;
	return [self.nextUpdateDate timeIntervalSinceNow];
}

- (void) stop
{
	self.updateBlock = nil;
	self.callback = nil;
	needsUpdateGeneration++;
	needsUpdateWhileWasInProgress = NO;
}

- (void) setNeedsUpdate
{
	[self setNeedsUpdate:nil];
}

- (void) setNeedsUpdate:(void(^)())callback
{
	self.callback = OABlockConcat(self.callback, callback);
	
	if (inProgress)
	{
		needsUpdateWhileWasInProgress = YES;
		return;
	}
	
	self.nextUpdateDate = [NSDate date];
	needsUpdateGeneration++;
	int gen = needsUpdateGeneration;
	
	// Resets delay interval
	delayInterval = initialDelay;
	
	dispatch_async(dispatch_get_current_queue(), ^{
		if (gen != needsUpdateGeneration) return;
		
		// set this flag here to let people call setNeedsUpdate multiple times during a cycle and cause only one update
		inProgress = YES;
		
		// Estimate the update up front - before it'll be refined upon completion.
		self.nextUpdateDate = [NSDate dateWithTimeIntervalSinceNow:delayInterval];
		if (self.updateBlock) self.updateBlock();
	});
}

- (void) ensureUpdatedOnce
{
	[self ensureUpdatedOnce:nil];
}

- (void) ensureUpdatedOnce:(void(^)())callback
{
	if (updatedOnce)
	{
		if (callback) callback();
		return;
	}
	
	if (inProgress)
	{
		self.callback = OABlockConcat(self.callback, callback);
		return;
	}
	
	[self setNeedsUpdate:callback];
}

- (void) didFinishUpdate
{
	inProgress = NO;
	updatedOnce = YES;
	if (needsUpdateWhileWasInProgress)
	{
		needsUpdateWhileWasInProgress = NO;
		[self setNeedsUpdate];
	}
	if (self.callback) self.callback();
	self.callback = nil;
}

- (void) delayUpdate
{
	[self delayUpdateByInterval:delayInterval];
}

- (void) delayUpdateByInterval:(NSTimeInterval)interval
{
	self.nextUpdateDate = [NSDate dateWithTimeIntervalSinceNow:interval];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		NSTimeInterval di = delayInterval;
		[self setNeedsUpdate];
		delayInterval = di;
	});
	
	NSTimeInterval plusMinusOne = (2*(0.5-drand48()));
	delayInterval = interval*delayMultiplier*(1.0 + 0.2*plusMinusOne);
	
	if (delayInterval > maximumDelay)
	{
		delayInterval = maximumDelay*(1.0 + 0.2*plusMinusOne);
	}
}

@end
