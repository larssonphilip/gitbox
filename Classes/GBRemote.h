@class GBRef;
@class GBRepository;
@interface GBRemote : NSObject

@property(nonatomic,retain) NSString* alias;
@property(nonatomic,retain) NSString* URLString;
@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* newBranches;
@property(nonatomic,retain) NSArray* tags;

@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) pushedAndNewBranches;


#pragma mark Actions

- (void) addBranch:(GBRef*)branch;
- (void) updateBranchesWithBlock:(void(^)())block;

@end
