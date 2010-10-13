@interface GBBaseRepositoryController : NSObject

@property(assign) BOOL displaysTwoPathComponents;

- (NSURL*) url;
- (NSString*) nameForSourceList;
- (NSString*) shortNameForSourceList;
- (NSString*) longNameForSourceList;
- (NSString*) parentFolderName;

- (void) setNeedsUpdateEverything;
- (void) updateRepositoryIfNeeded;

- (void) beginBackgroundUpdate;
- (void) endBackgroundUpdate;

- (void) start;
- (void) stop;

@end
