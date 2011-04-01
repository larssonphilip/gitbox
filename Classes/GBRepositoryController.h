#import "GBMainWindowItem.h"
#import "GBChangeDelegate.h"
#import "GBSidebarItemObject.h"

@class GBRepository;
@class GBRef;
@class GBRemote;
@class GBCommit;

@class GBSidebarItem;
@class GBRepositoryToolbarController;
@class GBRepositoryViewController;
@class OAFSEventStream;
@class OABlockQueue;

@interface GBRepositoryController : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain, readonly) NSURL* url;
@property(nonatomic, retain) OABlockQueue* updatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, assign) NSWindow* window;
@property(nonatomic, retain) GBRepositoryToolbarController* toolbarController;
@property(nonatomic, retain) GBRepositoryViewController* viewController;
@property(nonatomic, retain) GBCommit* selectedCommit;
@property(nonatomic, retain) OAFSEventStream* fsEventStream;
@property(nonatomic, retain) NSString* lastCommitBranchName;

@property(nonatomic, assign) NSInteger isRemoteBranchesDisabled;
@property(nonatomic, assign, readonly) NSInteger isDisabled;
@property(nonatomic, assign, readonly) NSInteger isSpinning;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (id) initWithURL:(NSURL*)aURL;

- (NSArray*) stageAndCommits;

- (void) start;
- (void) stop;

- (void) loadCommitsIfNeeded;

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

- (IBAction) fetch:(id)sender;
- (IBAction) pull:(id)sender;
- (IBAction) push:(id)sender;

- (BOOL) validateFetch:(id)sender;
- (BOOL) validatePull:(id)sender;
- (BOOL) validatePush:(id)sender;


// will be obsolete when settings UI is done
- (IBAction) editRepositories:(id)sender;
- (IBAction) editGitIgnore:(id)sender;
- (IBAction) editGitConfig:(id)sender;


@end
