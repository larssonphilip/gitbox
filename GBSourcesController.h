@class GBRepository;
@interface GBSourcesController : NSViewController<NSOutlineViewDataSource>
{
  NSMutableArray* localRepositories;
  NSOutlineView* outlineView;
}

@property(retain) NSMutableArray* localRepositories;
@property(retain) NSArray* nextViews;
@property(retain) IBOutlet NSOutlineView* outlineView;

- (GBRepository*) repositoryWithURL:(NSURL*)url;
- (void) addRepository:(GBRepository*)repo;
- (void) selectRepository:(GBRepository*)repo;

- (void) rememberRepositories;
- (void) restoreRepositories;

@end
