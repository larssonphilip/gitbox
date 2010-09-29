
#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;
@class OAPropertyListController;
@class OAFSEventStream;

@interface GBRepositoryController : NSObject
{
  NSUInteger pulling;
  NSUInteger pushing;
  NSUInteger merging;
  NSUInteger fetching;
  
  BOOL needsLocalBranchesUpdate;
  BOOL needsRemotesUpdate;
  BOOL needsCommitsUpdate;
  
  BOOL backgroundUpdateEnabled;
  NSTimeInterval backgroundUpdateInterval;
}

@property(retain) GBRepository* repository;
@property(retain) GBCommit* selectedCommit;
@property(nonatomic,retain) OAPropertyListController* plistController;
@property(retain) OAFSEventStream* fsEventStream;

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
- (void) updateCurrentBranchesIfNeededWithBlock:(void(^)())block;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;
- (void) selectRemoteBranch:(GBRef*) remoteBranch;



- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

- (void) loadCommits; // private


- (void) saveObject:(id)obj forKey:(NSString*)key;
- (id) loadObjectForKey:(NSString*)key;


#pragma mark Background Update

// FIXME: move to GBRepositoryController
- (void) resetBackgroundUpdateInterval;
//- (void) beginBackgroundUpdate;
//- (void) endBackgroundUpdate;


- (void) start;
- (void) stop;


@end
