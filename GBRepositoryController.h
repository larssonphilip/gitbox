
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
@property(assign) id<GBRepositoryControllerDelegate> delegate;

+ (id) repositoryControllerWithURL:(NSURL*)url;

- (NSURL*) url;

- (void) pushDisabled;
- (void) popDisabled;

- (void) pushSpinning;
- (void) popSpinning;

- (void) setNeedsUpdateEverything;
- (void) updateRepository;
- (void) checkoutRef:(GBRef*) ref;
- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

@end
