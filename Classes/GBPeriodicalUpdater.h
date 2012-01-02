/*
 
 Usage:
 
 1. Force update: [updater setNeedsUpdate]
 2. Update with block: [updater setNeedsUpdateWithBlock:^{ ... }]
 3. Update routine: updater.updateBlock = ^{
	 [self updateStageChangesWithBlock:^{
			 [updater didFinishUpdate];
			 if (changed) {
				[updater setNeedsUpdate];
			 }
			 else 
			 {
				[updater delayUpdate];
			 }
		 }];
	 }
 4. Custom delay: [updater delayUpdateByInterval:2.0];
 5. Multiplier: updater.delayMultiplier = 2.0;  // 2.0 is a default value
 6. Initial delay: updater.initialDelay = 1.0; // 1.0 is a default value
 
 */

#import <Foundation/Foundation.h>

@interface GBPeriodicalUpdater : NSObject

@property(nonatomic, assign) NSTimeInterval initialDelay;
@property(nonatomic, assign) NSTimeInterval maximumDelay;
@property(nonatomic, assign) double delayMultiplier;
- (NSTimeInterval) timeSinceLastUpdate;
- (NSTimeInterval) timeUntilNextUpdate;

// Returns new instance initialized with updateBlock
+ (GBPeriodicalUpdater*) updaterWithBlock:(void(^)())block;

// You must call it from updateBlock when finish updating something. This method invokes pending callbacks.
- (void) didFinishUpdate; 

// Forces update on the next runloop cycle.
- (void) setNeedsUpdate;

// Forces update on the next runloop cycle and adds block to be called when update is finished.
- (void) setNeedsUpdate:(void(^)())callback;

// Schedules update if none was yet scheduled.
- (void) ensureUpdatedOnce;

// Schedules update if none was yet scheduled. Callback is called immediately (if first update has finished already) or when current update is finished.
- (void) ensureUpdatedOnce:(void(^)())callback;

// Delays update by an automatically increased interval (using delayMultiplier property).
- (void) delayUpdate;

// Delays update by the specified interval and sets it as a current one.
- (void) delayUpdateByInterval:(NSTimeInterval)interval;

// Removes pending callbacks and breaks retain cycles in blocks.
- (void) stop;

@end
