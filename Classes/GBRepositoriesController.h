#import "GBNotificationMacros.h"

GBNotificationDeclare(GBRepositoriesControllerWillAddRepository);
GBNotificationDeclare(GBRepositoriesControllerDidAddRepository);
GBNotificationDeclare(GBRepositoriesControllerWillRemoveRepository);
GBNotificationDeclare(GBRepositoriesControllerDidRemoveRepository);
GBNotificationDeclare(GBRepositoriesControllerWillSelectRepository);
GBNotificationDeclare(GBRepositoriesControllerDidSelectRepository);

@class GBRepositoryController;

@interface GBRepositoriesController : NSObject

@property(retain) GBRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositoryControllers;

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url;
- (BOOL) isEmpty;

- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl;
- (void) setNeedsUpdateEverything;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
