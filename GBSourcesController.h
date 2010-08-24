@class GBRepository;
@interface GBSourcesController : NSViewController<NSOutlineViewDataSource>
{
}

@property(retain) NSArray* nextViews;

- (GBRepository*) repositoryWithURL:(NSURL*)url;
- (void) addRepository:(GBRepository*)repo;
- (void) selectRepository:(GBRepository*)repo;

@end
