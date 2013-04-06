@class GBRef;
@class GBRepository;
@interface GBRemote : NSObject

@property(nonatomic,copy) NSString* alias;
@property(nonatomic,copy) NSString* URLString;
@property(nonatomic,copy) NSString* fetchRefspec;
@property(nonatomic,strong) NSArray* branches;

@property(nonatomic,assign) BOOL needsFetch;
@property(nonatomic,weak) GBRepository* repository;


// Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) pushedAndNewBranches;
- (BOOL) copyInterestingDataFromRemoteIfApplicable:(GBRemote*)otherRemote;
- (NSString*) defaultFetchRefspec;
- (void) updateNewBranches;
- (void) updateBranches;


// Actions

- (BOOL) isTransientBranch:(GBRef*)branch;
- (void) addNewBranch:(GBRef*)branch;
- (void) updateBranchesSilently:(BOOL)silently withBlock:(void(^)())block;

@end
