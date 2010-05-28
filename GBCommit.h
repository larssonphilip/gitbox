@class GBChange;
@class GBRepository;
@class GBCommitCell;
@interface GBCommit : NSObject
{
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
- (BOOL) isMerge;
- (NSString*) longAuthorLine;
- (Class) cellClass;
- (GBCommitCell*) cell;


#pragma mark Mutation

- (void) updateChanges;
- (void) reloadChanges;
- (void) resetChanges; // to save memory

- (NSArray*) allChanges;
- (NSArray*) loadChanges;

- (void) asyncTaskGotChanges:(NSArray*)theChanges;

@end
