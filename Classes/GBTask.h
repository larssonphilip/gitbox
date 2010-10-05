#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
@property(assign) GBRepository* repository;
+ (id) taskWithRepository:(GBRepository*)repo;
+ (NSString*) pathToBundledBinary:(NSString*)name;
@end
