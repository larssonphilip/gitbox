#import "GBBaseChangesController.h"
@interface GBCommitViewController : GBBaseChangesController<NSSplitViewDelegate>
{
  NSData* headerRTFTemplate;
  
  IBOutlet NSScrollView* headerScrollView;
  IBOutlet NSTextView* headerTextView;
}
@property(nonatomic,retain) NSData* headerRTFTemplate;

@property(nonatomic,retain) IBOutlet NSScrollView* headerScrollView;
@property(nonatomic,retain) IBOutlet NSTextView* headerTextView;

- (IBAction) stageShowDifference:(id)sender;
- (IBAction) stageRevealInFinder:(id)sender;

@end
