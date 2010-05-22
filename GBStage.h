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

@property(retain) NSArray* stagedChanges;
@property(retain) NSArray* unstagedChanges;
@property(retain) NSArray* untrackedChanges;
@property(assign) BOOL hasStagedChanges;

- (void) stageChange:(GBChange*)change;
- (void) unstageChange:(GBChange*)change;

@end
