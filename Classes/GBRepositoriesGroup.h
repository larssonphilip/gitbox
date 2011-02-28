#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSidebarItem;
@class GBRepositoryController;
@interface GBRepositoriesGroup : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, retain) GBSidebarItem* sidebarItem;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSMutableArray* items;
@property(nonatomic, retain) NSProgressIndicator* sidebarSpinner;

+ (GBRepositoriesGroup*) untitledGroup;
- (NSString*) untitledGroupName;

- (void) insertObject:(id<GBSidebarItemObject>)anObject atIndex:(NSUInteger)anIndex;
- (void) removeObject:(id<GBSidebarItemObject>)anObject;

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)aURL;

@end
