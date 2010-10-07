#import "GBChangeDelegate.h"

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
- (BOOL) isDeletedFile;
- (BOOL) isUntrackedFile;
- (NSComparisonResult) compareByPath:(id) other;
- (NSString*) pathForIgnore;
- (GBChange*) nilIfBusy;

- (void) setStagedSilently:(BOOL) flag;
- (void) update;

- (NSURL*) existingOrTemporaryFileURL;

#pragma mark Actions

- (void) doubleClick:(id)sender;
- (void) launchDiffWithBlock:(void(^)())block;
- (BOOL) validateShowDifference;

- (void) revealInFinder;
- (void) openWithFinder;
- (BOOL) validateRevealInFinder;
- (BOOL) validateOpenWithFinder;

@end
