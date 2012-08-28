#import "GBRepositorySettingsViewController.h"

@interface GBRepositorySummaryController : GBRepositorySettingsViewController

@property(nonatomic) IBOutlet NSTextField* pathLabel;
@property(nonatomic) IBOutlet NSTextField* originLabel;

@property (weak) IBOutlet NSTextField *remoteLabel1;
@property (weak) IBOutlet NSTextField *remoteField1;
@property (weak) IBOutlet NSTextField *remoteLabel2;
@property (weak) IBOutlet NSTextField *remoteField2;
@property (weak) IBOutlet NSTextField *remoteLabel3;
@property (weak) IBOutlet NSTextField *remoteField3;
@property (weak) IBOutlet NSView *remainingView;
@property (unsafe_unretained) IBOutlet NSTextView *gitignoreTextView;

- (IBAction)openInFinder:(id)sender;

@end
