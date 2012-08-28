#import <Quartz/Quartz.h>
#import "GBChangeDelegate.h"

#define kGBChangeDiffToolKey   (@"diffTool")
#define kGBChangeSubmoduleMode (@"160000")

@class GBChangeCell;
@class GBRepository;
@class GBCommit;
@class GBSearchQuery;

@interface GBChange : NSObject<NSPasteboardWriting, QLPreviewItem>

@property(nonatomic,strong) NSURL* srcURL;
@property(nonatomic,strong) NSURL* dstURL;
@property(nonatomic,copy)   NSString* statusCode;
@property(nonatomic,copy)   NSString* status;
@property(nonatomic,copy)   NSString* srcMode;
@property(nonatomic,copy)   NSString* dstMode;
@property(nonatomic,assign) NSInteger statusScore;
@property(nonatomic,copy)   NSString* srcRevision;
@property(nonatomic,copy)   NSString* dstRevision;
@property(nonatomic,copy)   NSString* commitId;
@property(nonatomic,strong) GBSearchQuery* searchQuery;
@property(nonatomic,copy)   NSSet* highlightedPathSubstrings;
@property(nonatomic,assign) BOOL containsHighlightedDiffLines;

// Important: staged property & delegate are only used for checkbox binding in UI.
@property(nonatomic,assign) BOOL staged;
@property(nonatomic,weak) id<GBChangeDelegate> delegate;
@property(nonatomic,assign) BOOL busy;
@property(nonatomic,weak) GBRepository* repository;


+ (GBChange*) dummy; // for bindings in right view
+ (NSArray*) diffTools;
+ (NSString*) defaultDiffTool;


#pragma mark Interrogation

- (NSString*) defaultNameForExtractedFile;
- (NSString*) nameForExtractedFileWithSuffix;

- (NSURL*) fileURL;
- (NSString*) pathStatus;
- (BOOL) isAddedFile;
- (BOOL) isDeletedFile;
- (BOOL) isUntrackedFile;
- (BOOL) isMovedOrRenamedFile;
- (BOOL) isSubmodule;
- (BOOL) isDirtySubmodule;
- (NSComparisonResult) compareByPath:(id) other;
- (NSString*) pathForIgnore;
- (GBChange*) nilIfBusy;

- (BOOL) isRealChange;

- (void) setStagedSilently:(BOOL) flag;

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
