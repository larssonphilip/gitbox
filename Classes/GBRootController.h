// This controller provides an entry point to all other model controllers such as:
// - GBRepositoriesController (for local repositories),
// - GBSharedRepositoriesController (for bonjour-shared repos)
// - GBGithubAccountsController
// - GBGithubWatchedRepositoriesController
// etc.

// Notifications' selectors:
// - rootControllerDidChangeContents:(GBRootController*)aRootController
// - rootControllerDidChangeSelection:(GBRootController*)aRootController

#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSidebarItem;
@class GBRepositoriesController;
@class GBRepositoriesGroup;

@interface GBRootController : NSResponder<GBSidebarItemObject>

@property(nonatomic, strong, readonly)  GBSidebarItem* sidebarItem;
@property(nonatomic, strong, readonly)  GBRepositoriesController* repositoriesController;

@property(nonatomic, strong) NSArray* selectedObjects;
@property(nonatomic, strong) NSResponder<GBSidebarItemObject, GBMainWindowItem>* selectedObject;
@property(nonatomic, strong) NSResponder<GBSidebarItemObject, GBMainWindowItem>* clickedObject;
@property(nonatomic, strong) NSArray* selectedSidebarItems;
@property(nonatomic, strong) GBSidebarItem* selectedSidebarItem;
@property(nonatomic, strong) GBSidebarItem* clickedSidebarItem;
@property(nonatomic, strong) NSArray* selectedItemIndexes;
@property(unsafe_unretained, nonatomic, readonly) NSArray* clickedOrSelectedSidebarItems;
@property(unsafe_unretained, nonatomic, readonly) NSArray* clickedOrSelectedObjects;

- (void) addObjectsToSelection:(NSArray*)objects;
- (void) removeObjectsFromSelection:(NSArray*)objects;

// Returns NO if cannot open any of URLs
- (BOOL) openURLs:(NSArray*)URLs;

// Contained objects should send this message so that rootController could notify its listeners about content changes (refresh sidebar etc.)
- (void) contentsDidChange;

// A list of responders to be always present in responder chain (in order of priority)
- (NSArray*) staticResponders;

// RootController maintains its own chain of responders. This API lets to correctly affect only responder outside of internal chain.
- (NSResponder*) externalNextResponder;
- (void) setExternalNextResponder:(NSResponder*)aResponder;

- (BOOL) syncSelectedObjects;

@end
