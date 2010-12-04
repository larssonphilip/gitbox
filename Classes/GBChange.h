#import "GBChangeDelegate.h"
@class GBChangeCell;
@class GBRepository;
@interface GBChange : NSObject

@property(retain) NSURL* srcURL;
@property(retain) NSURL* dstURL;
@property(retain) NSString* statusCode;
@property(retain) NSString* status;
@property(retain) NSString* oldRevision;
@property(retain) NSString* newRevision;

// Important: staged property & delegate are only used for checkbox binding in UI.
@property(nonatomic,assign) BOOL staged;
@property(assign) id<GBChangeDelegate> delegate;
@property(assign) BOOL busy;
@property(assign) GBRepository* repository;

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
