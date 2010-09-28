typedef enum {
  GBCommitSyncStatusNormal = 0,
  GBCommitSyncStatusUnmerged,
  GBCommitSyncStatusUnpushed
} GBCommitSyncStatus;

@class GBChange;
@class GBRepository;
@class GBCommitCell;
@class GBStage;

@interface GBCommit : NSObject

@property(retain) NSString* commitId;
@property(retain) NSString* treeId;
@property(retain) NSString* authorName;
@property(retain) NSString* authorEmail;
@property(retain) NSString* committerName;
@property(retain) NSString* committerEmail;
@property(retain) NSDate* date;
@property(retain) NSString* message;
@property(retain) NSArray* parentIds;
@property(retain) NSArray* changes;

@property(assign) GBCommitSyncStatus syncStatus;
@property(assign) GBRepository* repository;


#pragma mark Interrogation

- (BOOL) isStage;
- (GBStage*) asStage;
- (BOOL) isMerge;
- (NSString*) longAuthorLine;
- (Class) cellClass;
- (GBCommitCell*) cell;

- (NSString*) fullDateString;
- (NSString*) tooltipMessage;

#pragma mark Mutation


- (void) loadChangesWithBlock:(void(^)())block;

//- (void) updateChanges;
//- (void) reloadChanges;
//
//- (NSArray*) allChanges;
//- (NSArray*) loadChanges;
//
//- (void) asyncTaskGotChanges:(NSArray*)theChanges;

@end
