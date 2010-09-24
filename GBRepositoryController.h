
#import "GBRepositoryControllerDelegate.h"

@class GBRepository;
@class GBRef;
@class GBCommit;

@class GBMainWindowController;

@interface GBRepositoryController : NSObject
{
  NSUInteger pulling;
  NSUInteger pushing;
  NSUInteger merging;
  NSUInteger fetching;
}

@property(retain) GBRepository* repository;
@property(retain) GBCommit* selectedCommit;

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
- (void) updateRepository;

- (void) checkoutRef:(GBRef*) ref;
- (void) checkoutRef:(GBRef*) ref withNewName:(NSString*)name;
- (void) checkoutNewBranchWithName:(NSString*)name;

- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

@end
