
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
@property(retain) GBMainWindowController* windowController;
@property(retain) GBCommit* selectedCommit;

- (NSURL*) url;

- (void) selectRepository:(GBRepository*) repo;
- (void) checkoutRef:(GBRef*) ref;
- (void) selectCommit:(GBCommit*)commit;
- (void) pull;
- (void) push;

@end
