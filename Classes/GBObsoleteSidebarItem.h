
@class GBBaseRepositoryController;
@protocol GBRepositoriesControllerLocalItem;
@protocol GBObsoleteSidebarItem <NSObject, NSPasteboardWriting>

- (NSString*) sidebarItemIdentifier;
- (NSString*) nameInSidebar;
- (NSString*) tooltipInSidebar;

- (NSInteger) numberOfChildrenInSidebar;
- (id<GBObsoleteSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (id<GBObsoleteSidebarItem>) findItemWithIndentifier:(NSString*)identifier;

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
