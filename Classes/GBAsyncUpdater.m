#import "GBAsyncUpdater.h"
#import "OABlockOperations.h"

//NSString* const GBAsyncUpdaterDidFinishNotification = @"GBAsyncUpdaterDidFinishNotification";
//NSString* const GBAsyncUpdaterWillBeginNotification = @"GBAsyncUpdaterWillBeginNotification";

@interface GBAsyncUpdater ()
@property(nonatomic, copy) void(^currentWaitBlock)(); // after completion of the current update
@property(nonatomic, copy) void(^nextWaitBlock)();    // after completion of the next update
@end

@implementation GBAsyncUpdater {
	BOOL _needsUpdate;
	BOOL _needsUpdateAfterCurrentUpdate; // set to YES if update is in progress
	BOOL _inProgress;
	
	int generation;
}

@synthesize target=_target;
@synthesize action=_action;
@synthesize currentWaitBlock;
@synthesize nextWaitBlock;


+ (GBAsyncUpdater*) updaterWithTarget:(id)target action:(SEL)action
{
	GBAsyncUpdater* updater = [[self alloc] init];
	updater.target = target;
	updater.action = action;
	return updater;
}

- (BOOL) needsUpdate
{
	return _needsUpdate || _needsUpdateAfterCurrentUpdate;
}

- (BOOL) isUpdating
{
	return _inProgress;
}

- (void) setNeedsUpdate
{
	if (!_inProgress)
	{
		if (!_needsUpdate)
		{
			//NSLog(@"GBAsyncUpdater: setNeedsUpdate: scheduling update");
			_needsUpdate = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				if (self.action) [self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop
			});
		}
	}
	else
	{
		//NSLog(@"GBAsyncUpdater: setNeedsUpdate: needs update after current update");
		_needsUpdateAfterCurrentUpdate = YES;
	}
}

- (void) waitUpdate:(void(^)())block
{
	if (!_inProgress && !_needsUpdate && !_needsUpdateAfterCurrentUpdate)
	{
		//NSLog(@"GBAsyncUpdater: waitUpdate: not in progress and does not need update, calling block");
		if (block) block();
	}
	else
	{
		if (!_needsUpdateAfterCurrentUpdate)
		{
			//NSLog(@"GBAsyncUpdater: waitUpdate: adding to current wait block");
			self.currentWaitBlock = OABlockConcat(self.currentWaitBlock, block);
		}
		else
		{
			//NSLog(@"GBAsyncUpdater: waitUpdate: adding to next wait block, after update");
			self.nextWaitBlock = OABlockConcat(self.nextWaitBlock, block);
		}
	}
}

- (void) beginUpdate
{
	// It is important to set _needsUpdate to NO here and not before target/action call.
	// The client may delay call to beginUpdate and we keep the "needs update" state until we really beginUpdate.
	_inProgress = YES;
	_needsUpdate = NO;
	
#if DEBUG
	generation++;
	int gen = generation;
	OADispatchDelayed(20.0, ^{
		if (gen == generation)
		{
			NSLog(@"GBAsyncUpdater[%@ -> %@] Was not finished for 20 seconds.", NSStringFromSelector(self.action), self.target);
		}
	});
#endif
}

- (void) endUpdate
{
	generation++;
	BOOL needsUpdateAgain = _needsUpdateAfterCurrentUpdate;
	void(^currentBlock)() = [self.currentWaitBlock copy];
	void(^nextBlock)() = [self.nextWaitBlock copy];

	// Clean up all state
	_inProgress = NO;
	_needsUpdateAfterCurrentUpdate = NO;
	_needsUpdate = NO;
	self.currentWaitBlock = nil;
	self.nextWaitBlock = nil;

	// Schedule another update if needed.
	self.currentWaitBlock = nextBlock;
	
	//NSLog(@"GBAsyncUpdater: endUpdate: needsUpdateAgain=%d  currentWaitBlock=%@", (int)needsUpdateAgain, self.currentWaitBlock);
	if (needsUpdateAgain || self.currentWaitBlock)
	{
		[self setNeedsUpdate];
	}
	
	//NSLog(@"GBAsyncUpdater: endUpdate: calling client: %@", currentBlock);
	// Get back to the waiting clients.
	if (currentBlock) currentBlock();
}


- (void) cancel
{
	_inProgress = NO;
	_needsUpdateAfterCurrentUpdate = NO;
	_needsUpdate = NO;
	self.currentWaitBlock = nil;
	self.nextWaitBlock = nil;
}


@end
