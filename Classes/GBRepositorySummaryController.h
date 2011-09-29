#import "GBRepositorySettingsViewController.h"

@interface GBRepositorySummaryController : GBRepositorySettingsViewController

@property(nonatomic, retain) IBOutlet NSTextField* pathLabel;
@property(nonatomic, retain) IBOutlet NSTextField* originLabel;

@property (assign) IBOutlet NSTextField *remoteLabel1;
@property (assign) IBOutlet NSTextField *remoteField1;
@property (assign) IBOutlet NSTextField *remoteLabel2;
@property (assign) IBOutlet NSTextField *remoteField2;
@property (assign) IBOutlet NSTextField *remoteLabel3;
@property (assign) IBOutlet NSTextField *remoteField3;
@property (assign) IBOutlet NSView *remainingView;
@property (assign) IBOutlet NSTextField *sizeField;
@property (assign) IBOutlet NSTextField *statsLineField;
@property (assign) IBOutlet NSTextView *gitignoreTextView;

- (IBAction)optimizeRepository:(NSButton*)sender;
- (IBAction)openInFinder:(id)sender;

@end
