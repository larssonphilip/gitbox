#import "GBCommitPromptController.h"

#import "NSString+OAStringHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBCommitPromptController

@synthesize value;
@synthesize textView;
@synthesize shortcutTipLabel;

@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;
@synthesize windowHoldingSheet;

+ (GBCommitPromptController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBCommitPromptController"] autorelease];
}

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.value = nil;
  self.textView = nil;
  self.shortcutTipLabel = nil;
  [super dealloc];
}

- (void) resetMagicFlags
{
  [self.shortcutTipLabel setHidden:YES];
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showShortcutTip) object:nil];
  addedNewLine = NO;
  removedNewLine = NO;
  finishedPlayingWithTooltip = NO;
}

- (IBAction) onOK:(id)sender
{
  [self resetMagicFlags];
  self.value = [self.textView string];
  
  if (!self.value || [self.value isEmptyString]) return;
  
  self.value = [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if (finishSelector) [self.target performSelector:finishSelector withObject:self];
  
  [self.textView setString:@""];
  
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (IBAction) onCancel:(id)sender
{
  [self resetMagicFlags];
  if (cancelSelector) [self.target performSelector:cancelSelector withObject:self];
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}



#pragma mark NSWindowDelegate


- (void) windowDidBecomeKey:(NSNotification*)notification
{
  [self.textView selectAll:self];
}



#pragma mark NSTextViewDelegate


- (BOOL)textView:(NSTextView*)aTextView
        shouldChangeTextInRange:(NSRange)affectedCharRange
        replacementString:(NSString*)replacementString
{
  if (!finishedPlayingWithTooltip)
  {
    if (!addedNewLine)
    {
      if (affectedCharRange.location == [[aTextView string] length] && 
          affectedCharRange.length == 0 && 
          [replacementString isEqualToString:@"\n"])
      {
        // Possibly unintended newline. Should display shortcut tip if no text is entered.
        addedNewLine = YES;
        [self performSelector:@selector(showShortcutTip) withObject:nil afterDelay:0.6];
      }
    }
    else
    {
      if (!removedNewLine &&
          affectedCharRange.location == ([[aTextView string] length] - 1) && 
          affectedCharRange.length == 1 && 
          [replacementString isEqualToString:@""])
      {
        // backspace entered. This usually happens when unintended new line is cancelled. Ignore it.
        removedNewLine = YES;
      }
      else
      {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showShortcutTip) object:nil];
        finishedPlayingWithTooltip = YES;
      }
    }    
  }
  return YES;
}


- (void) showShortcutTip
{
  [self.shortcutTipLabel setHidden:NO];
  finishedPlayingWithTooltip = YES;
}


@end
