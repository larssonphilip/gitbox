@class GBRepository;
@interface GBRemote : NSObject
{
  NSString* alias;
  NSString* URLString;
  NSArray* branches;
  
  GBRepository* repository;
}

@property(retain) NSString* alias;
@property(retain) NSString* URLString;
@property(retain) NSArray* branches;

@property(assign) GBRepository* repository;


#pragma mark Info

- (GBRef*) defaultBranch;


#pragma mark Actions

- (void) addBranch:(GBRef*)branch;

@end
