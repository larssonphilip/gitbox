#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBSidebarItem;
@class GBRepositoryController;
@class GBRepositoriesController;
@interface GBRepositoriesGroup : NSResponder<GBMainWindowItem, GBSidebarItemObject>

@property(nonatomic, strong) GBSidebarItem* sidebarItem;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, strong) NSMutableArray* items;
@property(nonatomic, unsafe_unretained) GBRepositoriesController* repositoriesController;

+ (GBRepositoriesGroup*) untitledGroup;
- (NSString*) untitledGroupName;

- (void) insertObject:(id<GBSidebarItemObject>)anObject atIndex:(NSUInteger)anIndex;
- (void) removeObject:(id<GBSidebarItemObject>)anObject;

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)aURL;

- (IBAction) rename:(id)sender;

@end
