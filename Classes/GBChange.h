#import <Quartz/Quartz.h>
#import "GBChangeDelegate.h"

@class GBChangeCell;
@class GBRepository;
@class GBCommit;
@interface GBChange : NSObject<NSPasteboardWriting, QLPreviewItem>

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


+ (GBChange*) dummy; // for bindings in right view
+ (NSArray*) diffTools;



#pragma mark Interrogation

- (NSString*) defaultNameForExtractedFile;
- (NSString*) nameForExtractedFileWithSuffix;

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

- (Class) cellClass;
- (GBChangeCell*) cell;

- (NSObject<NSPasteboardWriting>*) pasteboardItem;
- (id<QLPreviewItem>) QLPreviewItem;
- (void) prepareQuicklookItemWithBlock:(void(^)(BOOL didExtractFile))aBlock;

- (NSImage*) icon;
- (NSImage*) srcIconOrDstIcon;
- (NSImage*) srcIcon;
- (NSImage*) dstIcon;


#pragma mark Actions

- (void) doubleClick:(id)sender;
- (void) launchDiffWithBlock:(void(^)())block;
- (BOOL) validateShowDifference;

- (void) revealInFinder;
- (BOOL) validateRevealInFinder;


- (BOOL) validateExtractFile;
- (void) extractFileWithTargetURL:(NSURL*)aTargetURL;


@end
