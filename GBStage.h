#import "GBCommit.h"
@class GBTask;
@interface GBStage : GBCommit
{
  NSArray* stagedChanges;
  NSArray* unstagedChanges;
  NSArray* untrackedChanges;
  
  GBTask* stagedChangesTask;
  GBTask* unstagedChangesTask;
  GBTask* untrackedChangesTask;
}

@property(retain) NSArray* stagedChanges;
@property(retain) NSArray* unstagedChanges;
@property(retain) NSArray* untrackedChanges;

@property(retain) GBTask* stagedChangesTask;
@property(retain) GBTask* unstagedChangesTask;
@property(retain) GBTask* untrackedChangesTask;

- (NSArray*) stagedChanges;
- (NSArray*) unstagedChanges;
- (NSArray*) untrackedChanges;

@end
