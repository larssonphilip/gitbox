#import "GBBaseChangesController.h"
@class GBCommit;
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate, NSOpenSavePanelDelegate>

@property(retain) GBCommit* commit;
@property(retain) NSData* headerRTFTemplate;
@property(retain) IBOutlet NSTextView* headerTextView;
@property(retain) IBOutlet NSTextView* messageTextView;
@property(retain) IBOutlet NSBox* horizontalLine;
@property(retain) IBOutlet NSImageView* authorImage;

- (IBAction) stageExtractFile:_;

@end
