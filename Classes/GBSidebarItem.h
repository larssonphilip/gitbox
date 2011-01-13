
#define GBSidebarItemPasteboardType @"com.oleganza.gitbox.GBSidebarItemPasteboardType"

@class GBBaseRepositoryController;
@protocol GBSidebarItem <NSObject, NSPasteboardWriting>

- (NSString*) sidebarItemIdentifier;
- (NSString*) nameInSidebar;

- (NSInteger) numberOfChildrenInSidebar;
- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (id<GBSidebarItem>) findItemWithIndentifier:(NSString*)identifier;

- (GBBaseRepositoryController*) repositoryController;

- (BOOL) isRepository;
- (BOOL) isRepositoriesGroup;
- (BOOL) isSubmodule;

- (NSCell*) sidebarCell;
- (Class) sidebarCellClass;

- (BOOL) isExpandableInSidebar;
- (BOOL) isDraggableInSidebar;
- (BOOL) isEditableInSidebar;

@end
