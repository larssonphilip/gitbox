#import "GBRepositoriesControllerLocalItem.h"
#import "GBSidebarItem.h"

@interface GBRepositoriesGroup : NSObject<GBRepositoriesControllerLocalItem, GBSidebarItem>

@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSMutableArray* items;

+ (GBRepositoriesGroup*) untitledGroup;
- (NSString*) untitledGroupName;

- (void) insertLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem atIndex:(NSInteger)anIndex;

@end
