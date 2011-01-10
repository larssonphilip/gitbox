#import "GBSidebarItem.h"

@class GBRepository;

@interface GBSubmodule : NSObject<GBSidebarItem>

@property(nonatomic, retain) NSURL* remoteURL;

@property(nonatomic, retain) NSString* path;
@property(nonatomic, assign) GBRepository* repository;


#pragma mark Interrogation

- (NSURL*) localURL;
- (NSString*) localPath;

- (NSURL*) repositoryURL;
- (NSString*) repositoryPath;



#pragma mark Mutation

- (void) pullWithBlock:(void(^)())block;

@end