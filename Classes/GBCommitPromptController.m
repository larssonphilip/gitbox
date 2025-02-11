









// OBSOLETE


















#import "GBCommitPromptController.h"

#import "GBCommit.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"

@implementation GBCommitPromptController

@synthesize value;
@synthesize branchName;
@synthesize messageHistory;
@synthesize textView;
@synthesize shortcutTipLabel;
@synthesize branchHintLabel;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
  self.value = [[self.textView string] copy];
  
  if (!self.value || [self.value isEmptyString]) 
  {
    [self onCancel:sender];
    return;
  }
  
  self.value = [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  [self addMessageToHistory];
  [self rewindMessageHistory];
  
//  if (self.finishBlock) self.finishBlock();
  
  [self.branchHintLabel setStringValue:@""];
  [self.textView setString:@""];
//  [self endSheet];
}

- (IBAction) onCancel:(id)sender
{
  [self rewindMessageHistory];
  [self resetMagicFlags];
  self.value = [[self.textView string] copy];
//  if (self.cancelBlock) self.cancelBlock();
//  [self endSheet];
}







#pragma mark Message History



- (void) rewindMessageHistory
{
  messageHistoryIndex = 0;
}

- (void) addMessageToHistory
{
  if (self.value)
  {
    [self.messageHistory insertObject:self.value atIndex:0];
  }
  [self rewindMessageHistory];
}

- (IBAction) previousMessage:(id)sender
{
  NSString* message = [self.messageHistory objectAtIndex:messageHistoryIndex or:nil];
  if (message)
  {
    // If it is the first scroll back, stash away the current text
    if (messageHistoryIndex == 0)
    {
      self.value = [[self.textView string] copy];
    }
    [self.textView setString:message];
    [self.textView selectAll:nil];
    messageHistoryIndex++;
  }
}

- (IBAction) nextMessage:(id)sender
{
  if (messageHistoryIndex > 0)
  {
    messageHistoryIndex--;
    if (messageHistoryIndex == 0) // reached the last item, recover stashed message
    {
      if (!self.value) self.value = @"";
      [self.textView setString:self.value];
      [self.textView selectAll:nil];
    }
    else
    {
      NSString* message = [[self messageHistory] objectAtIndex:messageHistoryIndex-1 or:nil];
      if (message)
      {
        [self.textView setString:message];
        [self.textView selectAll:nil];
      }
    }
  }
}





#pragma mark NSWindowDelegate


- (void) updateWindow
{
  [self.branchHintLabel setStringValue:self.branchName ? self.branchName : @""];
  [self.textView setString:self.value ? [self.value copy] : @""];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
  self.value = [[self.textView string] copy];
}







#pragma mark NSTextViewDelegate


- (BOOL)textView:(NSTextView*)aTextView
        shouldChangeTextInRange:(NSRange)affectedCharRange
        replacementString:(NSString*)replacementString
{
//  [self rewindMessageHistory];
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
