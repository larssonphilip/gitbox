typedef enum {
  GBCommitSyncStatusNormal = 0,
  GBCommitSyncStatusUnmerged,
  GBCommitSyncStatusUnpushed
} GBCommitSyncStatus;

@class GBChange;
@class GBRepository;
@class GBCommitCell;
@class GBStage;
@class GBSearchQuery;

@interface GBCommit : NSObject

@property(nonatomic,copy) NSString* commitId;
@property(nonatomic,copy) NSString* treeId;
@property(nonatomic,copy) NSString* authorName;
@property(nonatomic,copy) NSString* authorEmail;
@property(nonatomic,copy) NSString* committerName;
@property(nonatomic,copy) NSString* committerEmail;
@property(nonatomic,copy) NSDate* date;
@property(nonatomic,assign) int rawTimestamp;
@property(nonatomic,copy) NSString* message;
@property(nonatomic,copy) NSArray* parentIds;
@property(nonatomic,retain) NSArray* changes;
@property(nonatomic,copy) NSArray* diffs; // array of dicts {"paths": "File.h b/File2.h", "lines": "line1\nline2\n"}
@property(nonatomic,retain) GBSearchQuery* searchQuery;
@property(nonatomic,retain) NSDictionary* foundRangesByProperties;

@property(nonatomic,assign) GBCommitSyncStatus syncStatus;
@property(nonatomic,assign) GBRepository* repository;

@property(nonatomic,copy) NSString* colorLabel;

#pragma mark Interrogation

- (BOOL) isStage;
- (GBStage*) asStage;
- (BOOL) isMerge;
- (NSString*) longAuthorLine;

- (NSString*) fullDateString;
- (NSString*) tooltipMessage;
- (NSString*) subject; // first line of the commit message
- (NSString*) shortSubject; // first line of the commit message, truncated if needed
- (NSString*) subjectForReply; // composite subject for reply from Gitbox by email
- (NSString*) subjectOrCommitIDForMenuItem; // Like 'Merge "adding support for undo/redo"' or 'Merge commit fe6412b5'

- (BOOL) matchesQuery;

- (NSArray*) tags;


#pragma mark Mutation

- (void) loadChangesWithBlock:(void(^)())block;

@end
