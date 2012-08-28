#import "GBBaseChangesController.h"

@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate, NSOpenSavePanelDelegate>

// Nib API

@property(strong) NSData* headerRTFTemplate;
@property(strong) IBOutlet NSTextView* headerTextView;
@property(strong) IBOutlet NSTextView* messageTextView;
@property(strong) IBOutlet NSBox* horizontalLine;
@property(strong) IBOutlet NSImageView* authorImage;

- (IBAction) stageExtractFile:_;

@end
