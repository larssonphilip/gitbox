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

@property(retain) NSString* alias;
@property(retain) NSString* URLString;
@property(retain) NSArray* branches;
@property(retain) NSArray* tags;

@property(assign) GBRepository* repository;


#pragma mark Interrogation

- (GBRef*) defaultBranch;
- (NSArray*) guessedBranches;


#pragma mark Actions

- (void) addBranch:(GBRef*)branch;
- (NSArray*) loadBranches;
- (void) asyncTaskGotBranches:(NSArray*)branchesList tags:(NSArray*)tagsList;

@end
