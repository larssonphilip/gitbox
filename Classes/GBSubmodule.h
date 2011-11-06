#import "GBSidebarItemObject.h"
#import "GBMainWindowItem.h"

@class GBRepository;
@class GBSidebarItem;
@class GBRepositoryController;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSResponder<GBSidebarItemObject, GBMainWindowItem>

@property(nonatomic, copy) NSURL* remoteURL;
@property(nonatomic, copy) NSString* path;
@property(nonatomic, copy) NSString* status;
@property(nonatomic, retain) GBRepositoryController* repositoryController;
@property(nonatomic, retain) GBSidebarItem* sidebarItem;

@property(nonatomic, assign) GBRepository* repository;


#pragma mark Interrogation

- (NSURL*) localURL;
- (NSString*) localPath;

- (NSURL*) repositoryURL;
- (NSString*) repositoryPath;

- (BOOL) isCloned;


#pragma mark Mutation

- (void) updateHeadWithBlock:(void(^)())block;

@end