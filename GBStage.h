#import "GBCommit.h"
@class GBTask;
@class GBChange;
@interface GBStage : GBCommit
{
  NSArray* stagedChanges;
  NSArray* unstagedChanges;
  NSArray* untrackedChanges;
}

@property(retain) NSArray* stagedChanges;
@property(retain) NSArray* unstagedChanges;
@property(retain) NSArray* untrackedChanges;

- (void) stageChange:(GBChange*)change;
- (void) unstageChange:(GBChange*)change;

@end
