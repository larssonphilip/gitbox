#import "GBChangeDelegate.h"
@class GBChangeCell;
@class GBRepository;
@class GBCommit;
@interface GBChange : NSObject

@property(nonatomic,retain) NSURL* srcURL;
@property(nonatomic,retain) NSURL* dstURL;
@property(nonatomic,retain) NSString* statusCode;
@property(nonatomic,retain) NSString* status;
@property(nonatomic,retain) NSString* oldRevision;
@property(nonatomic,retain) NSString* newRevision;
@property(nonatomic,copy)   NSString* commitId;

// Important: staged property & delegate are only used for checkbox binding in UI.
@property(nonatomic,assign) BOOL staged;
@property(nonatomic,assign) id<GBChangeDelegate> delegate;
@property(nonatomic,assign) BOOL busy;
@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

+ (NSArray*) diffTools;
- (NSURL*) fileURL;
- (NSString*) pathStatus;
- (BOOL) isAddedFile;
- (BOOL) isDeletedFile;
- (BOOL) isUntrackedFile;
- (BOOL) isMovedOrRenamedFile;
- (NSComparisonResult) compareByPath:(id) other;
- (NSString*) pathForIgnore;
- (GBChange*) nilIfBusy;

- (void) setStagedSilently:(BOOL) flag;
- (void) update;

- (NSURL*) existingOrTemporaryFileURL;

- (Class) cellClass;
- (GBChangeCell*) cell;


#pragma mark Actions

- (void) doubleClick:(id)sender;
- (void) launchDiffWithBlock:(void(^)())block;
- (BOOL) validateShowDifference;

- (void) revealInFinder;
- (BOOL) validateRevealInFinder;


- (BOOL) validateExtractFile;
- (NSString*) defaultNameForExtractedFile;
- (void) extractFileWithTargetURL:(NSURL*)aTargetURL;

@end
