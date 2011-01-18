
#define GBSidebarItemPasteboardType @"com.oleganza.gitbox.GBSidebarItemPasteboardType"

@class GBBaseRepositoryController;
@protocol GBRepositoriesControllerLocalItem;
@protocol GBSidebarItem <NSObject, NSPasteboardWriting>

- (NSString*) sidebarItemIdentifier;
- (NSString*) nameInSidebar;
- (NSString*) tooltipInSidebar;

- (NSInteger) numberOfChildrenInSidebar;
- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (id<GBSidebarItem>) findItemWithIndentifier:(NSString*)identifier;

- (GBBaseRepositoryController*) repositoryController;
- (id<GBRepositoriesControllerLocalItem>) repositoriesControllerLocalItem;

- (BOOL) isRepository;
- (BOOL) isRepositoriesGroup;
- (BOOL) isSubmodule;

- (NSCell*) sidebarCell;
- (Class) sidebarCellClass;

- (BOOL) isExpandableInSidebar;
- (BOOL) isDraggableInSidebar;
- (BOOL) isEditableInSidebar;

- (BOOL) isExpandedInSidebar;
- (void) setExpandedInSidebar:(BOOL)expanded;

- (BOOL) isSpinningInSidebar;
- (BOOL) isAccumulatedSpinningInSidebar;
- (NSProgressIndicator*) sidebarSpinner;
- (void) setSidebarSpinner:(NSProgressIndicator*)spinnerView;
- (void) hideAllSpinnersInSidebar;

- (NSInteger) badgeValue;
- (NSInteger) accumulatedBadgeValue;

@end
