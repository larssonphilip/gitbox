/*
 
 Usage:
 
 1. Force update: [updater setNeedsUpdate]
 2. Update routine: updater.updateBlock = ^{
	 [self updateStageChangesWithBlock:^{
			 if (changed) {
				[updater setNeedsUpdate];
			 }
			 else 
			 {
				[updater delayUpdate];
			 }
		 }];
	 }
 3. Custom delay: [updater delayUpdateByInterval:2.0];
 4. Multiplier: updater.delayMultiplier = 2.0;  // 2.0 is a default value
 5. Initial delay: updater.initialDelay = 1.0; // 1.0 is a default value
 
 */

#import <Foundation/Foundation.h>

@interface GBPeriodicalUpdater : NSObject

@property(nonatomic, copy) void(^updateBlock)();
@property(nonatomic, assign) NSTimeInterval initialDelay;
@property(nonatomic, assign) double delayMultiplier;
@property(nonatomic, assign) dispatch_queue_t queue;

- (void) setNeedsUpdate;
- (void) delayUpdate;
- (void) delayUpdateByInterval:(NSTimeInterval)interval;

@end
