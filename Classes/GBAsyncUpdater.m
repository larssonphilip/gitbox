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
}

@synthesize target=_target;
@synthesize action=_action;
@synthesize currentWaitBlock;
@synthesize nextWaitBlock;

- (void) dealloc
{
	self.currentWaitBlock = nil;
	self.nextWaitBlock = nil;
	[super dealloc];
}

+ (GBAsyncUpdater*) updaterWithTarget:(id)target action:(SEL)action
{
	GBAsyncUpdater* updater = [[[self alloc] init] autorelease];
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
		_needsUpdateAfterCurrentUpdate = NO;
		
		if (!_needsUpdate)
		{
			_needsUpdate = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				if (self.action) [self.target performSelector:self.action withObject:self];
			});
		}
	}
	else
	{
		_needsUpdateAfterCurrentUpdate = YES;
	}
}

- (void) waitUpdate:(void(^)())block
{
	if (!_inProgress)
	{
		if (block) block();
	}
	else
	{
		if (!_needsUpdateAfterCurrentUpdate)
		{
			self.currentWaitBlock = OABlockConcat(self.currentWaitBlock, block);
		}
		else
		{
			self.nextWaitBlock = OABlockConcat(self.currentWaitBlock, block);
		}
	}
}

- (void) beginUpdate
{
	// It is important to set _needsUpdate to NO here and not before target/action call.
	// The client may delay call to beginUpdate and we keep the "needs update" state until we really beginUpdate.
	_inProgress = YES;
	_needsUpdate = NO;
}

- (void) endUpdate
{
	BOOL needsUpdateAgain = _needsUpdateAfterCurrentUpdate;
	void(^currentBlock)() = [[self.currentWaitBlock copy] autorelease];
	void(^nextBlock)() = [[self.nextWaitBlock copy] autorelease];

	// Clean up all state
	_inProgress = NO;
	_needsUpdateAfterCurrentUpdate = NO;
	_needsUpdate = NO;
	self.currentWaitBlock = nil;
	self.nextWaitBlock = nil;

	// Schedule another update if needed.
	self.currentWaitBlock = nextBlock;
	if (needsUpdateAgain || self.currentWaitBlock)
	{
		[self setNeedsUpdate];
	}
	
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
