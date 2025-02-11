#import "GBCommit.h"
@class GBTask;
@class GBChange;

// Notification selectors:

// - (void) stageDidUpdateChanges:(GBStage*)aStage;

@interface GBStage : GBCommit

@property(nonatomic, strong) NSArray* stagedChanges;
@property(nonatomic, strong) NSArray* unstagedChanges;
@property(nonatomic, strong) NSArray* untrackedChanges;
@property(nonatomic, copy) NSString* currentCommitMessage;

- (BOOL) isRebaseConflict;
- (BOOL) isDirty;
- (BOOL) isStashable;
- (BOOL) isCommitable;
- (NSUInteger) totalPendingChanges;
// Returns a good default human-readable message like "somefile.c, other.txt, Makefile and 5 others"
- (NSString*) defaultStashMessage;

- (void) updateConflictState;
- (void) updateStageWithBlock:(void(^)(BOOL contentDidChange))block;

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) stageAllWithBlock:(void(^)())block;
- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) deleteFilesInChanges:(NSArray*)theChanges withBlock:(void(^)())block;

- (void) beginStageTransaction:(void(^)())block;
- (void) endStageTransaction;

@end
