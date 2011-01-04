@class GBRepository;

@interface GBSubmodule : NSObject

@property(nonatomic, retain) NSURL* remoteURL;

// Name and path are equal most of the time but
// they don't have to. See gitmodules(5). MK.
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSString* path;
@property(nonatomic, assign) BOOL busy;
@property(nonatomic, assign) GBRepository* repository;


#pragma mark Interrogation

- (NSURL*) localURL;
- (NSString*) localPath;

- (NSURL*) repositoryURL;
- (NSString*) repositoryPath;



#pragma mark Mutation

- (void) pullWithBlock:(void(^)())block;

@end