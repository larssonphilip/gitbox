#import "GBBasePromptController.h"

@class GBRepositoryController;
@interface GBCommitPromptController : GBBasePromptController
{
  NSUInteger messageHistoryIndex;
  BOOL addedNewLine;
  BOOL removedNewLine;
  BOOL finishedPlayingWithTooltip;
}
@property(retain) NSString* value;
@property(retain) NSString* branchName;
@property(retain) NSMutableArray* messageHistory;
@property(retain) IBOutlet NSTextView* textView;
@property(retain) IBOutlet NSTextField* shortcutTipLabel;
@property(retain) IBOutlet NSTextField* branchHintLabel;


#pragma mark Message History

- (void) addMessageToHistory;
- (void) rewindMessageHistory;
- (IBAction) previousMessage:(id)sender;
- (IBAction) nextMessage:(id)sender;

@end
