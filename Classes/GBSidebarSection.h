
#import "GBSidebarItem.h"

@interface GBSidebarSection : NSObject<GBSidebarItem>
@property(nonatomic,copy) NSString* name;
@property(nonatomic,retain) NSArray* items;

+ (GBSidebarSection*) sectionWithName:(NSString*)name items:(NSArray*)items;

@end
