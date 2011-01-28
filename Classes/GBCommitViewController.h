#import "GBBaseChangesController.h"

@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate, NSOpenSavePanelDelegate>

// Nib API

@property(retain) NSData* headerRTFTemplate;
@property(retain) IBOutlet NSTextView* headerTextView;
@property(retain) IBOutlet NSTextView* messageTextView;
@property(retain) IBOutlet NSBox* horizontalLine;
@property(retain) IBOutlet NSImageView* authorImage;

- (IBAction) stageExtractFile:_;

@end
