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

@property(nonatomic, assign) NSWindow* window; // window is assigned by the window as an owner of the reference to receiver

@property(nonatomic, retain) NSArray* selectedObjects;
@property(nonatomic, retain) NSResponder<GBSidebarItemObject, GBMainWindowItem>* selectedObject;
@property(nonatomic, retain) NSResponder<GBSidebarItemObject, GBMainWindowItem>* clickedObject;
@property(nonatomic, retain) NSArray* selectedSidebarItems;
@property(nonatomic, retain) GBSidebarItem* selectedSidebarItem;
@property(nonatomic, retain) GBSidebarItem* clickedSidebarItem;
@property(nonatomic, retain) GBSidebarItem* dropTargetSidebarItem;
@property(nonatomic, assign) NSInteger dropTargetIndex;
@property(nonatomic, retain) NSArray* selectedItemIndexes;
@property(nonatomic, readonly) NSArray* clickedOrSelectedSidebarItems;
@property(nonatomic, readonly) NSArray* clickedOrSelectedObjects;

- (void) addObjectsToSelection:(NSArray*)objects;
- (void) removeObjectsFromSelection:(NSArray*)objects;


// todo: should be private 
- (GBSidebarItem*) contextSidebarItemAndIndex:(NSUInteger*)anIndexRef;

// Returns NO if cannot open any of URLs
- (BOOL) openURLs:(NSArray*)URLs;

 // move to repositories controller
- (IBAction) addGroup:(id)sender;

- (void) moveItems:(NSArray*)items toSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex;
- (void) insertItems:(NSArray*)items inSidebarItem:(GBSidebarItem*)targetItem atIndex:(NSUInteger)insertionIndex;

// Contained objects should send this message so that rootController could notify its listeners about content changes (refresh sidebar etc.)
- (void) contentsDidChange;

// A list of responders to be always present in responder chain (in order of priority)
- (NSArray*) staticResponders;

@end
