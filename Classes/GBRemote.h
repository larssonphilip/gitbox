@class GBRef;
@class GBRepository;
@interface GBRemote : NSObject

@property(nonatomic,copy) NSString* alias;
@property(nonatomic,copy) NSString* URLString;
@property(nonatomic,copy) NSString* fetchRefspec;
@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* newBranches;

@property(nonatomic,assign) BOOL needsFetch;
@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) pushedAndNewBranches;
- (BOOL) copyInterestingDataFromRemoteIfApplicable:(GBRemote*)otherRemote;
- (BOOL) isConfiguredToFetchToTheDefaultLocation;
- (NSString*) defaultFetchRefspec;
- (void) updateNewBranches;

#pragma mark Actions

- (void) addNewBranch:(GBRef*)branch;
- (void) updateBranchesWithBlock:(void(^)())block;

@end
