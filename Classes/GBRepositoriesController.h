#import "GBNotificationMacros.h"

GBNotificationDeclare(GBRepositoriesControllerWillAddRepository);
GBNotificationDeclare(GBRepositoriesControllerDidAddRepository);
GBNotificationDeclare(GBRepositoriesControllerWillRemoveRepository);
GBNotificationDeclare(GBRepositoriesControllerDidRemoveRepository);

GBNotificationDeclare(GBRepositoriesControllerWillSelectRepository);
GBNotificationDeclare(GBRepositoriesControllerDidSelectRepository);
GBNotificationDeclare(GBRepositoriesControllerDidSelectLocalRepository);
GBNotificationDeclare(GBRepositoriesControllerDidSelectCloningRepository);

@class GBBaseRepositoryController;
@class GBRepositoryController;
@class GBCloningRepositoryController;

@interface GBRepositoriesController : NSObject

@property(retain) GBBaseRepositoryController* selectedRepositoryController;
@property(nonatomic,retain) NSMutableArray* localRepositoryControllers;

- (GBBaseRepositoryController*) repositoryControllerWithURL:(NSURL*)url;
- (BOOL) isEmpty;

- (GBRepositoryController*) selectedLocalRepositoryController;
- (GBCloningRepositoryController*) selectedCloningRepositoryController;

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl;
- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl;
- (void) setNeedsUpdateEverything;
- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

@end
