@class GBActivity;
@interface GBActivityController : NSWindowController <NSTableViewDelegate, NSWindowDelegate>

@property(nonatomic,retain) NSMutableArray* activities;
@property(nonatomic,retain) IBOutlet NSTextView* outputTextView;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* arrayController;

+ (id) sharedActivityController;

- (void) addActivity:(GBActivity*)activity;

@end
