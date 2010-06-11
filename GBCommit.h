

typedef enum {
  GBCommitSyncStatusNormal = 0,
  GBCommitSyncStatusUnmerged,
  GBCommitSyncStatusUnpushed
} GBCommitSyncStatus;



@class GBChange;
@class GBRepository;
@class GBCommitCell;
@interface GBCommit : NSObject
{
}

@property(nonatomic,retain) NSString* commitId;
@property(nonatomic,retain) NSString* treeId;
@property(nonatomic,retain) NSArray* parentIds;
@property(nonatomic,retain) NSString* authorName;
@property(nonatomic,retain) NSString* authorEmail;
@property(nonatomic,retain) NSString* committerName;
@property(nonatomic,retain) NSString* committerEmail;
@property(nonatomic,retain) NSDate* date;
@property(nonatomic,retain) NSString* message;

@property(nonatomic,retain) NSArray* changes;

@property(nonatomic,assign) GBCommitSyncStatus syncStatus;

@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (BOOL) isStage;
- (BOOL) isMerge;
- (NSString*) longAuthorLine;
- (Class) cellClass;
- (GBCommitCell*) cell;

- (NSString*) fullDateString;
- (NSAttributedString*) attributedHeader;
- (NSAttributedString*) attributedHeaderForAttributedString:(NSMutableAttributedString*)attributedString;

#pragma mark Mutation

- (void) updateChanges;
- (void) reloadChanges;
- (void) resetChanges; // to save memory

- (NSArray*) allChanges;
- (NSArray*) loadChanges;

- (void) asyncTaskGotChanges:(NSArray*)theChanges;

@end
