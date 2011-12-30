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

@property(nonatomic, copy) void(^updateBlock)();
@property(nonatomic, assign) NSTimeInterval initialDelay;
@property(nonatomic, assign) double delayMultiplier;

+ (GBPeriodicalUpdater*) updaterWithBlock:(void(^)())block;

- (NSTimeInterval) timeSinceLastUpdate;
- (NSTimeInterval) timeUntilNextUpdate;

- (void) didFinishUpdate; // should always be called from updateBlock when owner finishes update.
- (void) setNeedsUpdate;
- (void) setNeedsUpdateWithBlock:(void(^)())callback;
- (void) delayUpdate;
- (void) delayUpdateByInterval:(NSTimeInterval)interval;
- (void) stop;

@end
