#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
@property(nonatomic, unsafe_unretained) GBRepository* repository;
@property(nonatomic, assign) BOOL ignoreMissingRepository;
+ (BOOL) isSnowLeopard;
+ (id) taskWithRepository:(GBRepository*)repo;
+ (NSString*) pathToBundledBinary:(NSString*)name;
+ (NSString*) bundledGitVersion;
@end
