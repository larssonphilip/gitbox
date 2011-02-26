#import "GBRepositoriesControllerLocalItem.h"
#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSidebarItem;
@interface GBRepositoriesGroup : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSMutableArray* items;
@property(nonatomic, retain) NSProgressIndicator* sidebarSpinner;

+ (GBRepositoriesGroup*) untitledGroup;
- (NSString*) untitledGroupName;

- (void) insertObject:(id<GBSidebarItemObject>)anObject atIndex:(NSUInteger)anIndex;
// deprecated - (void) insertLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem atIndex:(NSInteger)anIndex;

@end
