#import "GBBaseRepositoryController.h"
#import "GBMainWindowItem.h"
#import "GBChangeDelegate.h"
#import "GBSidebarItemObject.h"
#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBRemote;
@class GBCommit;

@class GBSidebarItem;
@class GBRepositoryToolbarController;
@class GBRepositoryViewController;
@class OAFSEventStream;

@interface GBRepositoryController : GBBaseRepositoryController<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain, readonly) NSURL* url;
@property(nonatomic,retain) GBSidebarItem* sidebarItem;
@property(nonatomic,retain) GBRepositoryToolbarController* toolbarController;
@property(nonatomic,retain) GBRepositoryViewController* viewController;
@property(nonatomic,retain) GBCommit* selectedCommit;
@property(nonatomic,retain) OAFSEventStream* fsEventStream;
@property(nonatomic,retain) NSString* lastCommitBranchName;
@property(nonatomic,retain) NSData* urlBookmarkData;

@property(nonatomic,assign) NSInteger isRemoteBranchesDisabled;
@property(nonatomic,assign) id<GBRepositoryControllerDelegate> delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (id) initWithURL:(NSURL*)aURL;

// obsolete, use stageAndCommits - (NSArray*) commits;
- (NSArray*) stageAndCommits;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;
- (void) selectRemoteBranch:(GBRef*) remoteBranch;
- (void) createAndSelectRemoteBranchWithName:(NSString*)name remote:(GBRemote*)aRemote;

- (void) selectCommitId:(NSString*)commitId;

- (void) stageChanges:(NSArray*)changes;
- (void) stageChanges:(NSArray*)changes withBlock:(void(^)())block;
- (void) unstageChanges:(NSArray*)changes;
- (void) revertChanges:(NSArray*)changes;
- (void) deleteFilesInChanges:(NSArray*)changes;

- (void) commitWithMessage:(NSString*)message;

- (void) updateSubmodulesWithBlock:(void(^)())aBlock;

- (void) fetch;
- (void) pull;
- (void) push;

@end
