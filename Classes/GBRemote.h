@class GBRef;
@class GBRepository;
@interface GBRemote : NSObject

@property(nonatomic,copy) NSString* alias;
@property(nonatomic,copy) NSString* URLString;
@property(nonatomic,copy) NSString* fetchRefspec;
@property(nonatomic,retain) NSArray* branches;

@property(nonatomic,assign) BOOL needsFetch;
@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) pushedAndNewBranches;
- (BOOL) copyInterestingDataFromRemoteIfApplicable:(GBRemote*)otherRemote;
- (BOOL) isConfiguredToFetchToTheDefaultLocation;
- (NSString*) defaultFetchRefspec;
- (void) updateNewBranches;
- (void) updateBranches;


#pragma mark Actions

- (void) addNewBranch:(GBRef*)branch;
- (void) updateBranchesSilently:(BOOL)silently withBlock:(void(^)())block;

@end
