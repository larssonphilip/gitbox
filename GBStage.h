#import "GBCommit.h"
@interface GBStage : GBCommit

- (NSArray*) stagedChanges;
- (NSArray*) unstagedChanges;
- (NSArray*) untrackedChanges;

@end
