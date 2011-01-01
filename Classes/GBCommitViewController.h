#import "GBBaseChangesController.h"
@class GBCommit;
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate, NSOpenSavePanelDelegate>

@property(retain) GBCommit* commit;
@property(retain) NSData* headerRTFTemplate;
@property(retain) IBOutlet NSTextView* headerTextView;
@property(retain) IBOutlet NSTextView* messageTextView;

- (IBAction) stageExtractFile:_;

@end
