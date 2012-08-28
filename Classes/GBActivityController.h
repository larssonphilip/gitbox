@class GBActivity;
@interface GBActivityController : NSWindowController <NSTableViewDelegate, NSWindowDelegate>

@property(nonatomic,strong) NSMutableArray* activities;
@property(nonatomic,strong) IBOutlet NSTextView* outputTextView;
@property(nonatomic,strong) IBOutlet NSTableView* tableView;
@property(nonatomic,strong) IBOutlet NSArrayController* arrayController;

+ (id) sharedActivityController;

- (void) addActivity:(GBActivity*)activity;
- (IBAction)clearAll:(id)sender;

@end
