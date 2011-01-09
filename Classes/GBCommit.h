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

@property(nonatomic,retain) NSString* commitId;
@property(nonatomic,retain) NSString* treeId;
@property(nonatomic,retain) NSString* authorName;
@property(nonatomic,retain) NSString* authorEmail;
@property(nonatomic,retain) NSString* committerName;
@property(nonatomic,retain) NSString* committerEmail;
@property(nonatomic,retain) NSDate* date;
@property(nonatomic,retain) NSString* message;
@property(nonatomic,retain) NSArray* parentIds;
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


- (void) loadChangesWithBlock:(void(^)())block;

@end
