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

@property(nonatomic,copy) NSString* commitId;
@property(nonatomic,copy) NSString* treeId;
@property(nonatomic,copy) NSString* authorName;
@property(nonatomic,copy) NSString* authorEmail;
@property(nonatomic,copy) NSString* committerName;
@property(nonatomic,copy) NSString* committerEmail;
@property(nonatomic,copy) NSDate* date;
@property(nonatomic,copy) NSString* message;
@property(nonatomic,copy) NSArray* parentIds;
@property(nonatomic,retain) NSArray* changes;

@property(nonatomic,assign) GBCommitSyncStatus syncStatus;
@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (BOOL) isStage;
- (GBStage*) asStage;
- (BOOL) isMerge;
- (NSString*) longAuthorLine;
- (Class) cellClass;
- (GBCommitCell*) cell;

- (NSString*) fullDateString;
- (NSString*) tooltipMessage;
- (NSString*) subject; // first line of the commit message
- (NSString*) subjectForReply; // composite subject for reply from Gitbox by email

#pragma mark Mutation

- (void) loadChangesIfNeededWithBlock:(void(^)())block;
- (void) loadChangesWithBlock:(void(^)())block;

@end
