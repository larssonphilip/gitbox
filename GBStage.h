#import "GBCommit.h"
@class GBTask;
@class GBChange;
@interface GBStage : GBCommit

@property(nonatomic,retain) NSArray* stagedChanges;
@property(nonatomic,retain) NSArray* unstagedChanges;
@property(nonatomic,retain) NSArray* untrackedChanges;
@property(nonatomic,assign) BOOL hasStagedChanges;

- (BOOL) isDirty;

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) stageAllWithBlock:(void(^)())block;

- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) deleteFiles:(NSArray*)theChanges;


@end
