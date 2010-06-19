@class GBRepository;
@interface GBCommitPromptController : NSWindowController<NSWindowDelegate, NSTextViewDelegate>
{
  GBRepository* repository;
  NSString* value;
  
  NSUInteger messageHistoryIndex;
  
  IBOutlet NSTextView* textView;
  IBOutlet NSTextField* shortcutTipLabel;
  
  id target;
  SEL finishSelector;
  SEL cancelSelector;
  NSWindow* windowHoldingSheet;
  
  BOOL addedNewLine;
  BOOL removedNewLine;
  BOOL finishedPlayingWithTooltip;
}
@property(nonatomic,retain) GBRepository* repository;

@property(nonatomic,retain) NSString* value;

@property(nonatomic,retain) IBOutlet NSTextView* textView;
@property(nonatomic,retain) IBOutlet NSTextField* shortcutTipLabel;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;
@property(nonatomic,assign) NSWindow* windowHoldingSheet;

+ (GBCommitPromptController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

- (void) runSheetInWindow:(NSWindow*)window;


#pragma mark Message History

- (void) addMessageToHistory;

- (IBAction) previousMessage:(id)sender;
- (IBAction) nextMessage:(id)sender;



@end
