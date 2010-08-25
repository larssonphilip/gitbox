@class GBRepository;
@interface GBSourcesController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
}

@property(nonatomic,retain) NSMutableArray* sections;
@property(nonatomic,retain) NSMutableArray* localRepositories;
@property(nonatomic,retain) NSArray* nextViews;
@property(nonatomic,retain) IBOutlet NSOutlineView* outlineView;

- (GBRepository*) repositoryWithURL:(NSURL*)url;
- (void) addRepository:(GBRepository*)repo;
- (void) selectRepository:(GBRepository*)repo;

- (void) saveState;
- (void) loadState;

@end
