#import "GBRepositoriesGroup.h"

@class OABlockQueue;
@class GBRootController;
@class GBRepositoryViewController;
@class GBRepositoryToolbarController;
@class GBRepositoryController;

@interface GBRepositoriesController : GBRepositoriesGroup

@property(nonatomic, weak) GBRootController* rootController;
@property(nonatomic, strong) GBRepositoryViewController* repositoryViewController;
@property(nonatomic, strong) GBRepositoryToolbarController* repositoryToolbarController;

- (IBAction) openDocument:(id)sender;
- (IBAction) addGroup:(id)sender;
- (IBAction) remove:(id)sender;
- (void) cloneRepositoryAtURLString:(NSString*)URLString;
- (IBAction) cloneRepository:(id)sender;

- (BOOL) openURLs:(NSArray*)URLs;
- (BOOL) openURLs:(NSArray*)URLs inGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)anIndex;
- (BOOL) moveObjects:(NSArray*)objects toGroup:(GBRepositoriesGroup*)aGroup atIndex:(NSUInteger)anIndex;

- (void) contentsDidChange;

@end
