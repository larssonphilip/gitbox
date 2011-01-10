#import "GBSidebarItem.h"

@interface GBRepositoriesGroup : NSObject<GBSidebarItem>
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSArray* items;

- (NSString*) untitledGroupName;

@end
