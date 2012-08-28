#import <Foundation/Foundation.h>

//extern NSString* const GBAsyncUpdaterDidFinishNotification;
//extern NSString* const GBAsyncUpdaterWillBeginNotification;

@interface GBAsyncUpdater : NSObject

// Target is called when needs to begin an update.
@property(nonatomic, unsafe_unretained) id target;
@property(nonatomic, assign) SEL action;

+ (GBAsyncUpdater*) updaterWithTarget:(id)target action:(SEL)action;

// Returns YES if will update later.

- (BOOL) needsUpdate;


// Returns YES if already in process of updating.

- (BOOL) isUpdating;


// Tells updater to update as soon as possible.
// If update is already in progress, another update will be scheduled right after.

- (void) setNeedsUpdate;


// If in progress, calls block when updates are finished.
// If not in progress, calls immediately.

- (void) waitUpdate:(void(^)())block;


// Target should call these when its action is invoked.

- (void) beginUpdate;
- (void) endUpdate;

// Call to clean up all pending blocks
- (void) cancel;

@end
