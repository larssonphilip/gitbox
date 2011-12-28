#import "GBPeriodicalUpdater.h"

@interface GBPeriodicalUpdater ()
@end

@implementation GBPeriodicalUpdater {
	NSTimeInterval delayInterval;
	int needsUpdateGeneration;
}

@synthesize updateBlock;
@synthesize initialDelay;
@synthesize delayMultiplier;
@synthesize queue=_queue;

- (void) dealloc
{
	[updateBlock release];
	if (_queue) dispatch_release(_queue);
	[super dealloc];
}

- (id) init
{
	if (self = [super init])
	{
		initialDelay = 1.0;
		delayMultiplier = 2.0;
		delayInterval = initialDelay;
		self.queue = dispatch_get_main_queue();
	}
	return self;
}

- (void) setNeedsUpdate
{
	needsUpdateGeneration++;
	int gen = needsUpdateGeneration;
	dispatch_async(dispatch_get_main_queue(), ^{
		if (gen != needsUpdateGeneration) return;
		if (updateBlock) updateBlock();
	});
}

- (void) delayUpdate
{
	[self delayUpdateByInterval:delayInterval];
}

- (void) delayUpdateByInterval:(NSTimeInterval)interval
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (gen != needsUpdateGeneration) return;
		if (updateBlock) updateBlock();
	});
	delayInterval = interval*delayMultiplier;
}

- (void) setQueue:(dispatch_queue_t)queue
{
	if (queue == _queue) return;
	
	if (_queue) dispatch_release(_queue);
	_queue = queue;
	if (_queue) dispatch_retain(_queue);
}

@end
