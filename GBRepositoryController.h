
#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;
@class OAPropertyListController;

@interface GBRepositoryController : NSObject
{
  NSUInteger pulling;
  NSUInteger pushing;
  NSUInteger merging;
  NSUInteger fetching;
  
  BOOL backgroundUpdateEnabled;
  NSTimeInterval backgroundUpdateInterval;
}

@property(retain) GBRepository* repository;
@property(retain) GBCommit* selectedCommit;
@property(nonatomic,retain) OAPropertyListController* plistController;

@property(assign) NSInteger isDisabled;
@property(assign) NSInteger isSpinning;
@property(assign) NSObject<GBRepositoryControllerDelegate>* delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSURL*) url;
- (NSArray*) commits;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;
- (void) updateCurrentBranchesIfNeeded;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;




- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

- (void) loadCommits; // private


- (GBRef*) rememberedRemoteBranchForBranch:(GBRef*)localBranch;
- (void) rememberRemoteBranch:(GBRef*)remoteBranch forBranch:(GBRef*)localBranch;

- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Background Update

// FIXME: move to GBRepositoryController
- (void) resetBackgroundUpdateInterval;
//- (void) beginBackgroundUpdate;
//- (void) endBackgroundUpdate;


@end
