#import <Foundation/Foundation.h>

extern NSString* const GBAsyncUpdaterDidFinishNotification;
extern NSString* const GBAsyncUpdaterWillBeginNotification;

@interface GBAsyncUpdater : NSObject

// Target is called when needs to begin an update.
@property(nonatomic, assign) id target;
@property(nonatomic, assign) SEL action;

// Tells updater to update as soon as possible.
// If update is already in progress, another update will be scheduled right after.

- (void) setNeedsUpdate;


// If in progress, calls block when updates are finished.
// If not in progress, calls immediately.

- (void) waitUpdate:(void(^)())block;


// Target should call these when its action is invoked.

- (void) beginUpdate;
- (void) endUpdate;

@end
