
#define GBSidebarItemPasteboardType @"com.oleganza.gitbox.GBSidebarItemPasteboardType"

@class GBBaseRepositoryController;
@protocol GBSidebarItem <NSObject, NSPasteboardWriting>
- (NSString*) sidebarItemIdentifier;
- (NSInteger) numberOfChildrenInSidebar;
- (BOOL) isExpandableInSidebar;
- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index;
- (NSString*) nameInSidebar;
- (GBBaseRepositoryController*) repositoryController;
- (BOOL) isRepository;
- (BOOL) isRepositoriesGroup;
- (BOOL) isSubmodule;
- (NSCell*) sidebarCell;
- (Class) sidebarCellClass;
- (BOOL) isDraggableInSidebar;
@end
