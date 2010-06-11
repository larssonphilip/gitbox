#import "GBCommit.h"
@class GBTask;
@class GBChange;
@interface GBStage : GBCommit
{
  NSArray* stagedChanges;
  NSArray* unstagedChanges;
  NSArray* untrackedChanges;
  BOOL hasStagedChanges;
}

@property(nonatomic,retain) NSArray* stagedChanges;
@property(nonatomic,retain) NSArray* unstagedChanges;
@property(nonatomic,retain) NSArray* untrackedChanges;
@property(nonatomic,assign) BOOL hasStagedChanges;

- (BOOL) isDirty;

- (void) stageChange:(GBChange*)aChange;
- (void) stageChanges:(NSArray*)theChanges;
- (void) stageAll;
- (void) unstageChange:(GBChange*)aChange;
- (void) unstageChanges:(NSArray*)theChanges;
- (void) revertChanges:(NSArray*)theChanges;
- (void) deleteFiles:(NSArray*)theChanges;


@end
