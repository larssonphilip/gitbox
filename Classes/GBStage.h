#import "GBCommit.h"
@class GBTask;
@class GBChange;
@interface GBStage : GBCommit

@property(retain) NSArray* stagedChanges;
@property(retain) NSArray* unstagedChanges;
@property(retain) NSArray* untrackedChanges;
@property(assign) BOOL hasStagedChanges;
@property(assign) BOOL hasSelectedChanges;

- (BOOL) isDirty;
- (BOOL) isCommitable;

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) stageAllWithBlock:(void(^)())block;
- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) deleteFilesInChanges:(NSArray*)theChanges withBlock:(void(^)())block;

- (NSUInteger) totalPendingChanges;

@end
