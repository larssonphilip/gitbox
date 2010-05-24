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

@property(retain) NSURL* srcURL;
@property(retain) NSURL* dstURL;
@property(retain) NSString* statusCode;
@property(retain) NSString* oldRevision;
@property(retain) NSString* newRevision;

// Important: this property is only for checkbox binding in UI, do not use it programmatically.
@property(assign) BOOL staged;

@property(assign) GBRepository* repository;


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
