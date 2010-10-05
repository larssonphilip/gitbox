@class GBRepositoryController;
@interface GBCommitPromptController : NSWindowController<NSWindowDelegate, NSTextViewDelegate>
{
//  NSUInteger messageHistoryIndex;
  BOOL addedNewLine;
  BOOL removedNewLine;
  BOOL finishedPlayingWithTooltip;
}
@property(retain) NSString* value;
@property(retain) NSString* branchName;
@property(retain) IBOutlet NSTextView* textView;
@property(retain) IBOutlet NSTextField* shortcutTipLabel;
@property(retain) IBOutlet NSTextField* branchHintLabel;
@property(copy) void (^finishBlock)();
@property(copy) void (^cancelBlock)();

@property(nonatomic,assign) NSWindow* windowHoldingSheet;

+ (GBCommitPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;
- (void) endSheet;

- (void) updateWindow;

//#pragma mark Message History
//
//- (void) addMessageToHistory;
//- (void) rewindMessageHistory;
//- (IBAction) previousMessage:(id)sender;
//- (IBAction) nextMessage:(id)sender;



@end
