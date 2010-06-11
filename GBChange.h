@class GBRepository;
@interface GBChange : NSObject
{
  NSURL* srcURL;
  NSURL* dstURL;
  NSString* statusCode;
  NSString* oldRevision;
  NSString* newRevision;
  BOOL staged;
  
  GBRepository* repository;
}

@property(nonatomic,retain) NSURL* srcURL;
@property(nonatomic,retain) NSURL* dstURL;
@property(nonatomic,retain) NSString* statusCode;
@property(nonatomic,retain) NSString* oldRevision;
@property(nonatomic,retain) NSString* newRevision;

// Important: this property is only for checkbox binding in UI, do not use it programmatically.
@property(nonatomic,assign) BOOL staged;

@property(nonatomic,assign) GBRepository* repository;


#pragma mark Interrogation

- (NSURL*) fileURL;
- (NSString*) status;
- (NSString*) pathStatus;
- (BOOL) isDeletedFile;
- (BOOL) isUntrackedFile;
- (NSComparisonResult) compareByPath:(id) other;


#pragma mark Actions

- (void) launchComparisonTool:(id)sender;
- (void) revealInFinder:(id)sender;
- (BOOL) validateRevealInFinder:(id)sender;

- (void) unstage;
- (void) revert;
- (void) deleteFile;
- (void) moveToTrash;
- (void) gitRm;

@end
