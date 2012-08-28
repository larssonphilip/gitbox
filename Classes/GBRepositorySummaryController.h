#import "GBRepositorySettingsViewController.h"

@interface GBRepositorySummaryController : GBRepositorySettingsViewController

@property(nonatomic, strong) IBOutlet NSTextField* pathLabel;
@property(nonatomic, strong) IBOutlet NSTextField* originLabel;

@property (unsafe_unretained) IBOutlet NSTextField *remoteLabel1;
@property (unsafe_unretained) IBOutlet NSTextField *remoteField1;
@property (unsafe_unretained) IBOutlet NSTextField *remoteLabel2;
@property (unsafe_unretained) IBOutlet NSTextField *remoteField2;
@property (unsafe_unretained) IBOutlet NSTextField *remoteLabel3;
@property (unsafe_unretained) IBOutlet NSTextField *remoteField3;
@property (unsafe_unretained) IBOutlet NSView *remainingView;
@property (unsafe_unretained) IBOutlet NSTextView *gitignoreTextView;

- (IBAction)openInFinder:(id)sender;

@end
