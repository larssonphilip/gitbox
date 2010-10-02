#import "GBChangeDelegate.h"

@class GBRepository;
@interface GBChange : NSObject

@property(retain) NSURL* srcURL;
@property(retain) NSURL* dstURL;
@property(retain) NSString* statusCode;
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
- (NSString*) status;
- (NSString*) pathStatus;
- (BOOL) isDeletedFile;
- (BOOL) isUntrackedFile;
- (NSComparisonResult) compareByPath:(id) other;
- (NSString*) pathForIgnore;


#pragma mark Actions

- (void) launchComparisonTool:(id)sender;
- (void) revealInFinder:(id)sender;
- (BOOL) validateRevealInFinder:(id)sender;

//- (void) unstage;
- (void) revert;
- (void) deleteFile;
- (void) moveToTrash;
- (void) gitRm;

@end
