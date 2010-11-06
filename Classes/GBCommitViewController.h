#import "GBBaseChangesController.h"
@class GBCommit;
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate, NSOpenSavePanelDelegate>

@property(retain) GBCommit* commit;
@property(retain) NSData* headerRTFTemplate;
@property(retain) IBOutlet NSScrollView* headerScrollView;
@property(retain) IBOutlet NSTextView* headerTextView;

- (IBAction) stageExtractFile:_;

@end
