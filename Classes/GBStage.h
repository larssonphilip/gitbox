#import "GBCommit.h"
@class GBTask;
@class GBChange;

// Notification selectors:

// - (void) stageDidUpdateChanges:(GBStage*)aStage;
// - (void) stageDidFinishUpdatingChanges:(GBStage*)aStage;


@interface GBStage : GBCommit

@property(nonatomic, retain) NSArray* stagedChanges;
@property(nonatomic, retain) NSArray* unstagedChanges;
@property(nonatomic, retain) NSArray* untrackedChanges;
@property(nonatomic, copy) NSString* currentCommitMessage;
@property(nonatomic, retain, readonly) NSDate* lastUpdateDate; // check this to see if updateStage should be sent from FS monitor

- (BOOL) isRebaseConflict;
- (BOOL) isDirty;
- (BOOL) isStashable;
- (BOOL) isCommitable;
- (NSUInteger) totalPendingChanges;
// Returns a good default human-readable message like "somefile.c, other.txt, Makefile and 5 others"
- (NSString*) defaultStashMessage;

- (void) updateStage;
- (void) updateConflictState;

- (void) updateChangesAndCallOnFirstUpdate:(void(^)())block; // sets needsUpdate and adds block to the queue to be called on DidUpdateNotification
- (void) updateChangesAndCallWhenFinished:(void(^)())block; // sets needsUpdate and adds block to the queue to be called on DidUpdateNotification

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) stageAllWithBlock:(void(^)())block;
- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) deleteFilesInChanges:(NSArray*)theChanges withBlock:(void(^)())block;

@end
