#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
@property(nonatomic, assign) GBRepository* repository;
+ (BOOL) isSnowLeopard;
+ (id) taskWithRepository:(GBRepository*)repo;
+ (NSString*) pathToBundledBinary:(NSString*)name;
+ (NSString*) bundledGitVersion;
@end
