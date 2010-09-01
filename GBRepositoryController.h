
@class GBRepository;
@class GBRef;

@class GBMainWindowController;

@interface GBRepositoryController : NSObject

@property(retain) GBRepository* repository;
@property(retain) GBMainWindowController* windowController;

- (void) selectRepository:(GBRepository*) repo;
- (void) checkoutRef:(GBRef*) ref;

@end
