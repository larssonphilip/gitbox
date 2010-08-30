@class GBRepository;
@interface GBSourcesController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
  GBRepository* selectedRepository;
}

@property(nonatomic,retain) NSMutableArray* sections;
@property(nonatomic,retain) NSMutableArray* localRepositories;
@property(nonatomic,retain) GBRepository* selectedRepository;
@property(nonatomic,retain) NSArray* nextViews;
@property(nonatomic,retain) IBOutlet NSOutlineView* outlineView;

+ (NSString*) repositoryDidChangeNotificationName;

- (GBRepository*) repositoryWithURL:(NSURL*)url;
- (void) addRepository:(GBRepository*)repo;
- (void) selectRepository:(GBRepository*)repo;

- (void) saveState;
- (void) loadState;

- (IBAction) selectPreviousRepository:(id)_;
- (IBAction) selectNextRepository:(id)_;

@end
