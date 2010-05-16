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
@property(assign) BOOL staged;

@property(assign) GBRepository* repository;

- (NSURL*) fileURL;

- (NSString*) status;

- (NSString*) pathStatus;

- (BOOL) isDeletion;

- (NSComparisonResult) compareByPath:(id) other;

@end
