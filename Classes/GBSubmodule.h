@class GBRepository;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusJustCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSObject

@property(nonatomic, copy)   NSString* path;
@property(nonatomic, retain) NSURL* parentURL;
@property(nonatomic, retain) NSURL* remoteURL;
@property(nonatomic, copy)   NSString* status;
@property(nonatomic, copy)   NSString* commitId;

@property(nonatomic, readonly) NSURL* localURL;

@property(nonatomic, assign) dispatch_queue_t dispatchQueue;

@end