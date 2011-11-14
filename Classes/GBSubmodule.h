@class GBRepository;

extern NSString* const GBSubmoduleStatusNotCloned;
extern NSString* const GBSubmoduleStatusUpToDate;
extern NSString* const GBSubmoduleStatusNotUpToDate;

@interface GBSubmodule : NSObject

@property(nonatomic, copy) NSURL* remoteURL;
@property(nonatomic, copy) NSString* path;
@property(nonatomic, copy) NSString* status;
@property(nonatomic, assign) GBRepository* parentRepository;

@property(nonatomic, readonly) NSURL* localURL;
@property(nonatomic, readonly) BOOL isCloned;

- (void) updateHeadWithBlock:(void(^)())block;

@end