// This controller provides an entry point to all other model controllers such as:
// - GBRepositoriesController (for local repositories),
// - GBSharedRepositoriesController (for bonjour-shared repos)
// - GBGithubAccountsController
// - GBGithubWatchedRepositoriesController
// etc.

#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSidebarItem;
@class GBRepositoriesController;

@interface GBRootController : NSObject<GBSidebarItemObject>

@property(nonatomic, retain, readonly)  GBSidebarItem* sidebarItem;
@property(nonatomic, retain, readonly)  GBRepositoriesController* repositoriesController;

@property(nonatomic, retain) NSArray* selectedObjects;
@property(nonatomic, retain) id<GBSidebarItemObject, GBMainWindowItem> selectedObject;
@property(nonatomic, retain) NSArray* selectedSidebarItems;
@property(nonatomic, retain) GBSidebarItem* selectedSidebarItem;

// Returns NO if cannot open any of URLs
- (BOOL) openURLs:(NSArray*)URLs;

// Notifications:
// - (void) rootControllerDidChangeSelection:(GBRootController*)aRootController;

@end
