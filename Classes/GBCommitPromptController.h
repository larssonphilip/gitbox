














// OBSOLETE

























#import "GBBasePromptController.h"

@class GBRepositoryController;
@interface GBCommitPromptController : GBBasePromptController
{
  NSUInteger messageHistoryIndex;
  BOOL addedNewLine;
  BOOL removedNewLine;
  BOOL finishedPlayingWithTooltip;
}
@property(strong) NSString* value;
@property(strong) NSString* branchName;
@property(strong) NSMutableArray* messageHistory;
@property(strong) IBOutlet NSTextView* textView;
@property(strong) IBOutlet NSTextField* shortcutTipLabel;
@property(strong) IBOutlet NSTextField* branchHintLabel;


#pragma mark Message History

- (void) addMessageToHistory;
- (void) rewindMessageHistory;
- (IBAction) previousMessage:(id)sender;
- (IBAction) nextMessage:(id)sender;

@end
