#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
@property(assign) GBRepository* repository;
+ (id) taskWithRepository:(GBRepository*)repo;
+ (NSString*) pathToBundledBinary:(NSString*)name;

- (NSString*) executableName;


# pragma mark Execution environment

- (NSString*) launchPath;
- (NSString*) currentDirectoryPath;


#pragma mark Helpers

- (void) prepareTask;
@end
