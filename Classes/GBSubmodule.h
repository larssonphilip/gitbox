#import "GBSidebarItem.h"

@class GBRepository;
@class GBBaseRepositoryController;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSObject<GBSidebarItem>

@property(nonatomic, copy) NSURL* remoteURL;
@property(nonatomic, copy) NSString* path;
@property(nonatomic, copy) NSString* status;
@property(nonatomic, retain) GBBaseRepositoryController* repositoryController;

@property(nonatomic, assign) GBRepository* repository;



#pragma mark Interrogation

- (NSURL*) localURL;
- (NSString*) localPath;

- (NSURL*) repositoryURL;
- (NSString*) repositoryPath;

- (BOOL) isCloned;


#pragma mark Mutation

- (void) pullWithBlock:(void(^)())block;

@end