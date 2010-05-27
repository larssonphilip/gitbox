@class GBChange;
@class GBRepository;
@interface GBCommit : NSObject
{
  NSString* commitId;
  NSString* treeId;
  NSArray*  parentIds;
  NSString* authorName;
  NSString* authorEmail;
  NSDate* date;
  NSString* message;
  
  NSArray* changes;
  
  GBRepository* repository;
}

@property(retain) NSString* commitId;
@property(retain) NSString* treeId;
@property(retain) NSArray* parentIds;
@property(retain) NSString* authorName;
@property(retain) NSString* authorEmail;
@property(retain) NSDate* date;
@property(retain) NSString* message;

@property(retain) NSArray* changes;

@property(assign) GBRepository* repository;


#pragma mark Interrogation

- (BOOL) isStage;
- (id) myself;


#pragma mark Mutation

- (void) updateChanges;
- (void) reloadChanges;
- (void) resetChanges; // to save memory

- (NSArray*) allChanges;
- (NSArray*) loadChanges;

- (void) asyncTaskGotChanges:(NSArray*)theChanges;

@end
