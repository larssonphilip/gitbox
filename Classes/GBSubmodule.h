@class GBRepository;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusJustCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSObject

@property(nonatomic, copy)   NSString* path;
@property(nonatomic, strong) NSURL* parentURL;
@property(nonatomic, strong) NSURL* remoteURL;
@property(nonatomic, copy)   NSString* status;
@property(nonatomic, copy)   NSString* commitId;

@property(unsafe_unretained, nonatomic, readonly) NSURL* localURL;

@property(nonatomic, assign) dispatch_queue_t dispatchQueue;

- (id) plistRepresentation;
- (void) setPlistRepresentation:(id)plist;

@end