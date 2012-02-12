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

@property(nonatomic, retain, readonly)  GBSidebarItem* sidebarItem;
@property(nonatomic, retain, readonly)  GBRepositoriesController* repositoriesController;

@property(nonatomic, retain) NSArray* selectedObjects;
@property(nonatomic, retain) NSResponder<GBSidebarItemObject, GBMainWindowItem>* selectedObject;
@property(nonatomic, retain) NSResponder<GBSidebarItemObject, GBMainWindowItem>* clickedObject;
@property(nonatomic, retain) NSArray* selectedSidebarItems;
@property(nonatomic, retain) GBSidebarItem* selectedSidebarItem;
@property(nonatomic, retain) GBSidebarItem* clickedSidebarItem;
@property(nonatomic, retain) NSArray* selectedItemIndexes;
@property(nonatomic, readonly) NSArray* clickedOrSelectedSidebarItems;
@property(nonatomic, readonly) NSArray* clickedOrSelectedObjects;

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
