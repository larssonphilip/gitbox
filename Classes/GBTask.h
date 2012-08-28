#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
@property(nonatomic, weak) GBRepository* repository;
@property(nonatomic, assign) BOOL ignoreMissingRepository;
+ (BOOL) isSnowLeopard;
+ (id) taskWithRepository:(GBRepository*)repo;
+ (NSString*) pathToBundledBinary:(NSString*)name;
+ (NSString*) bundledGitVersion;
@end
