#import "GBAsyncUpdater.h"
#import "OABlockOperations.h"

NSString* const GBAsyncUpdaterDidFinishNotification = @"GBAsyncUpdaterDidFinishNotification";
NSString* const GBAsyncUpdaterWillBeginNotification = @"GBAsyncUpdaterWillBeginNotification";

@interface GBAsyncUpdater ()
@property(nonatomic, copy) void(^currentWaitBlock)(); // after completion of the current update
@property(nonatomic, copy) void(^nextWaitBlock)();    // after completion of the next update
@end

@implementation GBAsyncUpdater {
	BOOL _needsUpdate;
	BOOL _needsUpdateAfterCurrentUpdate; // set to YES if update is in progress
	BOOL _inProgress;
}

@synthesize target;
@synthesize action;
@synthesize currentWaitBlock;
@synthesize nextWaitBlock;

- (void) dealloc
{
	self.currentWaitBlock = nil;
	self.nextWaitBlock = nil;
	[super dealloc];
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
				[self.target performSelector:self.action withObject:self];
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
	_inProgress = YES;
	_needsUpdate = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:GBAsyncUpdaterWillBeginNotification object:self];
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
	
	if (currentBlock) currentBlock();
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GBAsyncUpdaterDidFinishNotification object:self];
	
	self.currentWaitBlock = nextBlock;
	
	if (needsUpdateAgain || self.currentWaitBlock)
	{
		[self setNeedsUpdate];
	}
}


@end
