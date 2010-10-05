@class OAActivity;
@interface GBActivityController : NSWindowController <NSTableViewDelegate, NSWindowDelegate>
{
  NSMutableArray* activities;
  IBOutlet NSTextView* outputTextView;
  IBOutlet NSTableView* tableView;
  IBOutlet NSArrayController* arrayController;
}

@property(nonatomic,retain) NSMutableArray* activities;
@property(nonatomic,retain) IBOutlet NSTextView* outputTextView;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* arrayController;

+ (id) sharedActivityController;

- (void) addActivity:(OAActivity*)activity;

@end
