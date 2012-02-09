@class GBRepository;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusJustCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSObject

@property(nonatomic, copy) NSURL* remoteURL;
@property(nonatomic, copy) NSString* path;
@property(nonatomic, copy) NSString* status;
@property(nonatomic, copy) NSString* commitId;
@property(nonatomic, assign) GBRepository* parentRepository;

@property(nonatomic, readonly) NSURL* localURL;

- (void) updateHeadWithBlock:(void(^)())block;

@end