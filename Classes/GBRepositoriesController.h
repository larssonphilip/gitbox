#import "GBRepositoriesGroup.h"

@class OABlockQueue;
@class GBRootController;
@class GBRepositoryViewController;
@class GBRepositoryToolbarController;
@class GBRepositoryController;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, assign) GBRootController* rootController;
@property(nonatomic, retain) OABlockQueue* localRepositoriesUpdatesQueue;
@property(nonatomic, retain) OABlockQueue* autofetchQueue;
@property(nonatomic, retain) GBRepositoryViewController* repositoryViewController;
@property(nonatomic, retain) GBRepositoryToolbarController* repositoryToolbarController;

// Actions

- (IBAction) openDocument:(id)sender;
- (IBAction) addGroup:(id)sender;
- (IBAction) remove:(id)sender;
- (IBAction) cloneRepository:(id)sender;

- (BOOL) openURLs:(NSArray*)URLs;
- (BOOL) openURLs:(NSArray*)URLs inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)anIndex;
- (BOOL) moveObjects:(NSArray*)objects toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)anIndex;

- (void) contentsDidChange;

@end
