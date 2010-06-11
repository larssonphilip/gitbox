@class GBRef;
@class GBRepository;
@interface GBRemote : NSObject
{
  NSString* alias;
  NSString* URLString;
  NSArray* branches;
  NSArray* tags;
  
  GBRepository* repository;
}

@property(nonatomic,retain) NSString* alias;
@property(nonatomic,retain) NSString* URLString;
@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* tags;

@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) guessedBranches;


#pragma mark Actions

- (void) addBranch:(GBRef*)branch;
- (NSArray*) loadBranches;

@end
