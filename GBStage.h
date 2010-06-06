#import "GBCommit.h"
@class GBTask;
@class GBChange;
@interface GBStage : GBCommit
{
}

@property(retain) NSArray* stagedChanges;
@property(retain) NSArray* unstagedChanges;
@property(retain) NSArray* untrackedChanges;
@property(assign) BOOL hasStagedChanges;

- (BOOL) isDirty;

- (void) stageChange:(GBChange*)aChange;
- (void) stageChanges:(NSArray*)theChanges;
- (void) stageAll;
- (void) unstageChange:(GBChange*)aChange;
- (void) unstageChanges:(NSArray*)theChanges;
- (void) revertChanges:(NSArray*)theChanges;
- (void) deleteFiles:(NSArray*)theChanges;


@end
