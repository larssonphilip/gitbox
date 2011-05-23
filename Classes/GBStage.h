#import "GBCommit.h"
@class GBTask;
@class GBChange;

@interface GBStage : GBCommit

@property(nonatomic, retain) NSArray* stagedChanges;
@property(nonatomic, retain) NSArray* unstagedChanges;
@property(nonatomic, retain) NSArray* untrackedChanges;
@property(nonatomic, copy) NSString* currentCommitMessage;

@property(nonatomic, assign) BOOL hasStagedChanges;

- (BOOL) isDirty;
- (BOOL) isCommitable;

- (NSUInteger) totalPendingChanges;

// Returns a good default human-readable message like "somefile.c, other.txt, Makefile and 5 others"
- (NSString*) defaultStashMessage;

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) stageAllWithBlock:(void(^)())block;
- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block;
- (void) deleteFilesInChanges:(NSArray*)theChanges withBlock:(void(^)())block;

@end
