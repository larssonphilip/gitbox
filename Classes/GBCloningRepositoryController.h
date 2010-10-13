@interface GBCloningRepositoryController : NSObject

@property(retain) NSURL* sourceURL;
@property(retain) NSURL* url;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;

- (void) start;
- (void) stop;

@end
