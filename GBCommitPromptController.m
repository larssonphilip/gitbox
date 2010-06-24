#import "GBCommitPromptController.h"

#import "GBModels.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBCommitPromptController

@synthesize repository;
@synthesize value;
@synthesize lastBranchName;
@synthesize textView;
@synthesize shortcutTipLabel;
@synthesize branchHintLabel;
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
  self.repository = nil;
  self.value = nil;
  self.lastBranchName = nil;
  self.textView = nil;
  self.shortcutTipLabel = nil;
  self.branchHintLabel = nil;
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
  
  [self addMessageToHistory];
  
  self.value = [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  self.lastBranchName = self.repository.currentLocalRef.name;
  [self.branchHintLabel setStringValue:@""];
  
  if (finishSelector) [self.target performSelector:finishSelector withObject:self];
  
  [self.textView setString:@""];
  
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (IBAction) onCancel:(id)sender
{
  [self rewindMessageHistory];
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





#pragma mark Message History


- (NSArray*) messageHistory
{
  NSArray* list = (NSArray*)[self.repository loadObjectForKey:@"GBCommitPromptMessageHistory"];
  if (!list) list = [NSArray array];
  return list;
}

- (void) rewindMessageHistory
{
  messageHistoryIndex = 0;
}

- (void) addMessageToHistory
{
  if (self.value)
  {
    NSArray* newHistory = [[NSArray arrayWithObject:self.value] arrayByAddingObjectsFromArray:[self messageHistory]];
    [self.repository saveObject:newHistory forKey:@"GBCommitPromptMessageHistory"];
  }
  messageHistoryIndex = 0;
}

- (NSString*) messageFromHistoryAtIndex:(NSUInteger)index
{
  return [[self messageHistory] objectAtIndex:index or:nil];
}

- (IBAction) previousMessage:(id)sender
{
  NSString* message = [[self messageHistory] objectAtIndex:messageHistoryIndex or:nil];
  if (message)
  {
    // If it is the first scroll back, stash away current text
    if (messageHistoryIndex == 0)
    {
      self.value = [[[self.textView string] copy] autorelease];
      NSLog(@"stashing current text %@", self.value);
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


- (void) updateBranchHint
{
  NSString* currentBranchName = self.repository.currentLocalRef.name;
  if (self.lastBranchName && currentBranchName && ![self.lastBranchName isEqualToString:currentBranchName])
  {
    [self.branchHintLabel setStringValue:currentBranchName];
  }
  else
  {
    [self.branchHintLabel setStringValue:@""];
  }
}

- (void) windowDidBecomeKey:(NSNotification*)notification
{
  [self updateBranchHint];
}

- (void) windowDidLoad
{
  [self updateBranchHint];
}



#pragma mark NSTextViewDelegate


- (BOOL)textView:(NSTextView*)aTextView
        shouldChangeTextInRange:(NSRange)affectedCharRange
        replacementString:(NSString*)replacementString
{
  [self rewindMessageHistory];
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
