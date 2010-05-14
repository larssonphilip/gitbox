@interface GBChange : NSObject
{
  NSURL* url;
  NSString* status;
  NSString* oldRevision;
  NSString* newRevision;
  BOOL staged;
}

@property(retain) NSURL* url;
@property(retain) NSString* status;
@property(retain) NSString* oldRevision;
@property(retain) NSString* newRevision;
@property(assign) BOOL staged;

@end
