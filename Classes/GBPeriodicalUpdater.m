#import "GBPeriodicalUpdater.h"
#import "OABlockOperations.h"

@interface GBPeriodicalUpdater ()
@property(nonatomic, copy) void(^callback)();
@property(nonatomic, retain) NSDate* lastUpdateDate;
@property(nonatomic, retain) NSDate* nextUpdateDate;
@end

@implementation GBPeriodicalUpdater {
	NSTimeInterval delayInterval;
	int needsUpdateGeneration;
}

@synthesize updateBlock;
@synthesize initialDelay;
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
		delayMultiplier = 2.0;
		delayInterval = initialDelay;
	}
	return self;
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
}

- (void) setNeedsUpdate
{
	[self setNeedsUpdateWithBlock:nil];
}

- (void) setNeedsUpdateWithBlock:(void(^)())callback
{
	self.nextUpdateDate = [NSDate date];
	self.callback = OABlockConcat(self.callback, callback);
	
	needsUpdateGeneration++;
	int gen = needsUpdateGeneration;
	dispatch_async(dispatch_get_current_queue(), ^{
		if (gen != needsUpdateGeneration) return;
		if (self.updateBlock) self.updateBlock();
		if (self.callback) self.callback();
	});
}

- (void) delayUpdate
{
	[self delayUpdateByInterval:delayInterval];
}

- (void) delayUpdateByInterval:(NSTimeInterval)interval
{
	self.nextUpdateDate = [NSDate dateWithTimeIntervalSinceNow:interval];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[self setNeedsUpdate];
	});
	delayInterval = interval*delayMultiplier;
}

@end
