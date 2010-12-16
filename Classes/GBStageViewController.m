#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBStageViewController.h"
#import "GBFileEditingController.h"
#import "GBCommitPromptController.h"
#import "GBUserNameEmailController.h"

#import "NSObject+OAKeyValueObserving.h"
#import "NSArray+OAArrayHelpers.h"

@class GBStageViewController;
@interface GBStageHeaderAnimation : NSAnimation
@property(nonatomic, copy) NSString* message;
@property(nonatomic, assign) GBStageViewController* controller;
@property(nonatomic, assign) NSRect headerFrame;
@property(nonatomic, assign) NSRect textScrollViewFrame;
@property(nonatomic, assign) CGFloat buttonAlpha;

+ (GBStageHeaderAnimation*) animationWithController:(GBStageViewController*)ctrl;
@end

@interface GBStageViewController ()
@property(nonatomic, retain) GBCommitPromptController* commitPromptController;
@property(nonatomic, retain) NSIndexSet* rememberedSelectionIndexes;
@property(nonatomic, retain) GBStageHeaderAnimation* headerAnimation;
@property(nonatomic, assign) BOOL alreadyCheckedUserNameAndEmail;
- (void) checkUserNameAndEmailIfNeededWithBlock:(void(^)())block;
- (void) updateHeader;
- (void) updateHeaderSizeAnimating:(BOOL)animating;
- (void) updateCommitButtonEnabledState;
- (void) syncHeaderAfterLeaving;
- (BOOL) validateCommit:(id)sender;
- (BOOL) validateReallyCommit:(id)sender;
- (BOOL) isEditingCommitMessage;
- (NSString*) validCommitMessage;
@end



@implementation GBStageViewController

@synthesize stage;
@synthesize messageTextScrollView;
@synthesize messageTextView;
@synthesize commitButton;
@synthesize commitPromptController;
@synthesize rememberedSelectionIndexes;
@synthesize headerAnimation;

@synthesize alreadyCheckedUserNameAndEmail;

#pragma mark Init

- (void) dealloc
{
  self.stage = nil;
  self.messageTextScrollView = nil;
  self.messageTextView = nil;
  self.commitButton = nil;
  self.commitPromptController = nil;
  self.rememberedSelectionIndexes = nil;
  self.headerAnimation = nil;
  [super dealloc];
}

- (void) loadView
{
  [super loadView];
  [self update];
  
  [self.tableView registerForDraggedTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeFileURL, NSStringPboardType, NSFilenamesPboardType, nil]];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
  [self.tableView setVerticalMotionCanBeginDrag:YES];
  
  
  //[self.messageTextView setC]
  [self.messageTextView setTextContainerInset:NSMakeSize(0.0, 3.0)];
  //[self.messageTextView setTextContainerInset:NSMakeSize(2.0, 2.0)];
}

- (void) update
{
  [super update];
  for (GBChange* change in self.changes)
  {
    change.delegate = self.repositoryController;
  }
  [self.statusArrayController arrangeObjects:self.changes];
  [self updateHeader];
  [self.tableView setNextKeyView:self.messageTextView];
}

- (void) updateWithChanges:(NSArray*)newChanges
{
  // Here we have to save selection, replace changes and restore selection. 
  NSMutableSet* selectedURLs = [NSMutableSet set];
  for (GBChange* aChange in [self selectedChanges])
  {
    if (aChange.srcURL) [selectedURLs addObject:aChange.srcURL];
    if (aChange.dstURL) [selectedURLs addObject:aChange.dstURL];
  }
  
  self.changes = newChanges;
  [self update];
  
  NSMutableArray* newSelectedChanges = [NSMutableArray array];
  for (GBChange* aChange in [self.statusArrayController arrangedObjects])
  {
    if (aChange.fileURL && [selectedURLs containsObject:aChange.fileURL])
    {
      [newSelectedChanges addObject:aChange];
    }
  }
  
  [self.statusArrayController setSelectedObjects: newSelectedChanges];
}








#pragma mark Actions



- (IBAction) stageDoStage:(id)sender
{
  [self.repositoryController stageChanges:[self selectedChanges]];
}

- (BOOL) validateStageDoStage:(id)sender
{
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges count] < 1) return NO;
  return ![selChanges allAreTrue:@selector(staged)];
}


- (IBAction) stageDoUnstage:(id)sender
{
  [self.repositoryController  unstageChanges:[self selectedChanges]];
}
- (BOOL) validateStageDoUnstage:(id)sender
{
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges count] < 1) return NO;
  return [selChanges anyIsTrue:@selector(staged)];
}


- (IBAction) stageDoStageUnstage:(id)sender
{
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges allAreTrue:@selector(staged)])
  {
    [self.repositoryController unstageChanges:selChanges];
  }
  else
  {
    [self.repositoryController stageChanges:selChanges];
  }
}
- (BOOL) validateStageDoStageUnstage:(id)sender
{
  if ([sender isKindOfClass:[NSMenuItem class]])
  {
    NSMenuItem* item = sender;
    [item setTitle:NSLocalizedString(@"Stage", @"Command")];
    NSArray* selChanges = [self selectedChanges];
    if ([selChanges allAreTrue:@selector(staged)])
    {
      [item setTitle:NSLocalizedString(@"Unstage", @"Command")];
    }
  }
  
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges count] < 1) return NO;
  return YES;
}


- (IBAction) stageIgnoreFile:(id)sender
{
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges count] < 1) return;
  NSArray* paths = [selChanges valueForKey:@"pathForIgnore"];

  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".gitignore";
  fileEditor.URL = [[self.stage.repository url] URLByAppendingPathComponent:@".gitignore"];
  fileEditor.linesToAppend = paths;
  [fileEditor runSheetInWindow:[self window]];
}
- (BOOL) validateStageIgnoreFile:(id)sender
{
  NSArray* selChanges = [self selectedChanges];
  if ([selChanges count] < 1) return NO;
  return YES;
}


- (IBAction) stageRevertFile:(id)sender
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"App")];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"App")];
  [alert setMessageText:NSLocalizedString(@"Revert selected files to last committed state?", @"Stage")];
  [alert setInformativeText:NSLocalizedString(@"All non-committed changes will be lost.",@"Stage")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(stageRevertFileAlertDidEnd:returnCode:contextInfo:)
                      contextInfo:[[self selectedChanges] copy]];
}
- (BOOL) validateStageRevertFile:(id)sender
{
  // returns YES when non-empty and array has something to revert
  return ![[self selectedChanges] allAreTrue:@selector(isUntrackedFile)]; 
}

- (void) stageRevertFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(NSArray*)changes
{
  if (returnCode == NSAlertFirstButtonReturn)
  {
    [self.repositoryController revertChanges:changes];
  }
  [changes autorelease];
  [NSApp endSheet:[self window]];
  [[alert window] orderOut:self];
  [alert autorelease];
}

- (IBAction) stageDeleteFile:(id)sender
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
  [alert setMessageText:NSLocalizedString(@"Delete selected files?", @"Stage")];
  [alert setInformativeText:NSLocalizedString(@"All non-committed changes will be lost.", @"Stage")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(stageDeleteFileAlertDidEnd:returnCode:contextInfo:)
                      contextInfo:[[self selectedChanges] copy]];  
}

- (BOOL) validateStageDeleteFile:(id)sender
{
  // returns YES when non-empty and array has something to delete
  if ([[self selectedChanges] allAreTrue:@selector(isDeletedFile)]) return NO;
  if ([[self selectedChanges] allAreTrue:@selector(staged)]) return NO;
  return YES;
}

- (void) stageDeleteFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(NSArray*)changes
{
  if (returnCode == NSAlertFirstButtonReturn)
  {
    [self.repositoryController deleteFilesInChanges:changes];
  }
  [changes autorelease];
  [NSApp endSheet:[self window]];
  [[alert window] orderOut:self];
  [alert autorelease];
}


- (void) commitWithSheet:(id)sender
{
  
  if (!self.commitPromptController)
  {
    self.commitPromptController = [[[GBCommitPromptController alloc] initWithWindowNibName:@"GBCommitPromptController"] autorelease];
  }
  
  GBCommitPromptController* prompt = self.commitPromptController;
  GBRepositoryController* repoCtrl = self.repositoryController;
  
  prompt.messageHistory = self.repositoryController.commitMessageHistory;
  prompt.value = repoCtrl.cancelledCommitMessage ? repoCtrl.cancelledCommitMessage : @"";
  prompt.branchName = nil;
  
  [prompt updateWindow];
  
  NSString* currentBranchName = self.repositoryController.repository.currentLocalRef.name;
  
  if (currentBranchName && 
      repoCtrl.lastCommitBranchName && 
      ![repoCtrl.lastCommitBranchName isEqualToString:currentBranchName])
  {
    prompt.branchName = currentBranchName;
  }
  
  prompt.finishBlock = ^{
    repoCtrl.cancelledCommitMessage = @"";
    repoCtrl.lastCommitBranchName = currentBranchName;
    [repoCtrl commitWithMessage:prompt.value];
  };
  prompt.cancelBlock = ^{
    repoCtrl.cancelledCommitMessage = prompt.value;
  };
  
  [prompt runSheetInWindow:[self window]];
}

- (IBAction) commit:(id)sender
{
  if ([self isEditingCommitMessage])
  {
    if ([self validateReallyCommit:sender])
    {
      [self reallyCommit:sender];
    }
  }
  else
  {
    [self checkUserNameAndEmailIfNeededWithBlock:^{
      [self.repositoryController stageChanges:[self selectedChanges] withBlock:^{
        //[self commitWithSheet:sender];
        [[self.messageTextView window] makeFirstResponder:self.messageTextView];
      }];
    }];
  }
}


- (BOOL) validateCommit:(id)sender
{
  return [self.stage isCommitable];
}

- (IBAction) reallyCommit:(id)sender
{
  NSString* msg = [self validCommitMessage];
  if (!msg) return;
  [self.repositoryController commitWithMessage:msg];
  [self.messageTextView setString:@""];
  self.stage.currentCommitMessage = nil;
  [[self.view window] makeFirstResponder:self.tableView];
  if (self.rememberedSelectionIndexes)
  {
    NSUInteger firstIndex = [self.rememberedSelectionIndexes firstIndex];
    if (firstIndex == NSNotFound) firstIndex = 1;
    [self.statusArrayController setSelectionIndex:firstIndex];
  }
  else
  {
    [self.statusArrayController setSelectionIndex:1];
  }
  [self updateCommitButtonEnabledState];
}

- (BOOL) validateReallyCommit:(id)sender
{
  return [self validateCommit:sender] && [self validCommitMessage];
}

- (NSString*) validCommitMessage
{
  NSString* msg = [[[self.messageTextView string] copy] autorelease];
  msg = [msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([msg length] < 1)
  {
    msg = nil;
  }
  return msg;
}








#pragma mark NSTextViewDelegate


- (void) textView:(NSTextView*)aTextView willBecomeFirstResponder:(BOOL)result
{
  if (!result) return;
  self.rememberedSelectionIndexes = [self.statusArrayController selectionIndexes];
  [self.statusArrayController setSelectionIndexes:[NSIndexSet indexSet]];
  
  if (!self.stage.currentCommitMessage)
  {
    [self.messageTextView setString:@""];
  }
  
  self.stage.currentCommitMessage = [[[self.messageTextView string] copy] autorelease];
  if (!self.stage.currentCommitMessage)
  {
    self.stage.currentCommitMessage = @"";
  }
  [self updateHeaderSizeAnimating:YES];
  [self.tableView scrollToBeginningOfDocument:nil];
}

- (void) textView:(NSTextView*)aTextView willResignFirstResponder:(BOOL)result
{
  if (!result) return;
  [self syncHeaderAfterLeaving];
}

- (void) textView:(NSTextView*)aTextView didCancel:(id)sender
{
  if (self.rememberedSelectionIndexes)
  {
    [self.statusArrayController setSelectionIndexes:self.rememberedSelectionIndexes];
  }
  [[self.view window] makeFirstResponder:self.tableView];
}

- (void)textDidChange:(NSNotification *)aNotification
{
  self.stage.currentCommitMessage = [[[self.messageTextView string] copy] autorelease];
  [self updateHeaderSizeAnimating:NO];
}

- (void) syncHeaderAfterLeaving
{
  NSString* msg = [self validCommitMessage];
  self.stage.currentCommitMessage = msg;
  // This toggling hack helps to reset cursor blinking when message view resigned first responder.
  [self.messageTextView setHidden:YES];
  [self.messageTextView setHidden:NO];
  [self updateHeaderSizeAnimating:YES];
}

- (void) updateHeader
{
  NSString* msg = [[self.stage.currentCommitMessage copy] autorelease];
  if (!msg) msg = @"";
  [self.messageTextView setString:msg];
  [self updateHeaderSizeAnimating:NO];
}

- (void) updateHeaderSizeAnimating:(BOOL)animating
{
  static CGFloat idleTextHeight = 14.0;
  static CGFloat idleTextScrollViewHeight = 23.0;
  static CGFloat idleHeaderViewHeight = 39.0;
  static CGFloat bonusLineHeight = 11.0;
  static CGFloat bottomButtonSpaceHeight = 24.0;
  static CGFloat topPadding = 7.0;
  
  if (self.headerAnimation)
  {
    [self.headerAnimation stopAnimation];
    self.headerAnimation.controller = nil; // make sure animation does not touch us.
    self.headerAnimation = nil;
  }
    
  NSRect newHeaderFrame = self.headerView.frame;
  NSRect newTextScrollViewFrame = self.messageTextScrollView.frame;
  CGFloat textHeight = [[self.messageTextView layoutManager] usedRectForTextContainer:[self.messageTextView textContainer]].size.height;
  CGFloat newButtonAlpha = 0.0;
  NSString* newMessage = nil;
  
  if (!self.stage.currentCommitMessage)
  {
    // idle mode: button hidden, textview has a single-line appearance
    newHeaderFrame.size.height = textHeight + (idleHeaderViewHeight - idleTextHeight);
    newTextScrollViewFrame.size.height = idleTextScrollViewHeight;
    newButtonAlpha = 0.0;
    newMessage = NSLocalizedString(@"Commit Message...", @"Commit");
    [self.messageTextView setString:@""];
    [self.messageTextView setTextColor:[NSColor disabledControlTextColor]];
  }
  else
  {
    // editing mode: textview has an additional line, button is visible
    newHeaderFrame.size.height = textHeight + (idleHeaderViewHeight - idleTextHeight) + bonusLineHeight + bottomButtonSpaceHeight;
    newTextScrollViewFrame.size.height = newHeaderFrame.size.height - (idleHeaderViewHeight - idleTextScrollViewHeight) - bottomButtonSpaceHeight;
    newButtonAlpha = 1.0;
    [self.messageTextView setTextColor:[NSColor blackColor]];
  }
  
  newTextScrollViewFrame.origin.y = newHeaderFrame.size.height - newTextScrollViewFrame.size.height - topPadding;
  
  if (!animating)
  {
    self.headerView.frame = newHeaderFrame;
    self.messageTextScrollView.frame = newTextScrollViewFrame;
    if (newMessage) [self.messageTextView setString:newMessage];
    [self.commitButton setHidden:newButtonAlpha < 0.5];
    [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
  }
  else
  {
    self.headerAnimation = [GBStageHeaderAnimation animationWithController:self];
   // [self.headerAnimation setDelegate:self];
    self.headerAnimation.headerFrame = newHeaderFrame;
    self.headerAnimation.textScrollViewFrame = newTextScrollViewFrame;
    self.headerAnimation.buttonAlpha = newButtonAlpha;
    self.headerAnimation.message = newMessage;
    [self.headerAnimation performSelector:@selector(startAnimation) withObject:nil afterDelay:0.0];
  }
  
  [self updateCommitButtonEnabledState];
}


- (BOOL) validateSelectLeftPane:(id)sender
{
  return ![self isEditingCommitMessage] && [super validateSelectLeftPane:sender];
}

- (BOOL) isEditingCommitMessage
{
  return ([[self.view window] firstResponder] == self.messageTextView);
}

- (void) updateCommitButtonEnabledState
{
  [self.commitButton setEnabled:[self validateReallyCommit:nil]];
}








#pragma mark NSTableViewDelegate



// The problem: http://www.cocoadev.com/index.pl?CheckboxInTableWithoutSelectingRow
- (BOOL)tableView:(NSTableView*)aTableView 
  shouldTrackCell:(NSCell*)aCell
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(NSInteger)aRow
{
  // This allows clicking the checkbox without selecting the row
  return YES;
}

// This avoids changing selection when checkbox is clicked.
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  NSEvent *currentEvent = [[aTableView window] currentEvent];
  if([currentEvent type] != NSLeftMouseDown) return YES;
  // you may also check for the NSLeftMouseDragged event
  // (changing the selection by holding down the mouse button and moving the mouse over another row)
  int columnIndex = [aTableView columnAtPoint:[aTableView convertPoint:[currentEvent locationInWindow] fromView:nil]];
  if (columnIndex < 0) return NO;
  
  if (columnIndex < [[aTableView tableColumns] count])
  {
    if ([[[[aTableView tableColumns] objectAtIndex:columnIndex] identifier] isEqual:@"staged"])
    {
      return NO;
    }
  }
  return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.repositoryController selectCommitableChanges:[self selectedChanges]];
}

- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)indexSet
     toPasteboard:(NSPasteboard *)pasteboard
{
  NSArray* items = [[self.changes objectsAtIndexes:[self changesIndexesForTableIndexes:indexSet]] valueForKey:@"pasteboardItem"];
  [pasteboard writeObjects:items];
  return YES;
}



#pragma mark User name and email


- (void) checkUserNameAndEmailIfNeededWithBlock:(void(^)())block
{
  if (self.alreadyCheckedUserNameAndEmail)
  {
    block();
    return;
  }
  
  NSString* email = [GBRepository globalConfiguredEmail];
  
  if (email && [email length] > 3)
  {
    self.alreadyCheckedUserNameAndEmail = YES;
    block();
    return;
  }
  
  GBUserNameEmailController* ctrl = [[[GBUserNameEmailController alloc] initWithWindowNibName:@"GBUserNameEmailController"] autorelease];
  [ctrl fillWithAddressBookData];
  ctrl.finishBlock = ^{
    self.alreadyCheckedUserNameAndEmail = YES;
    [GBRepository configureName:ctrl.userName email:ctrl.userEmail withBlock:block];
  };
  [ctrl runSheetInWindow:[self window]];
}


@end








@interface GBStageHeaderAnimation ()
@property(nonatomic, assign) CGFloat topPadding;
@property(nonatomic, assign) NSRect headerFrameInitial;
@property(nonatomic, assign) NSRect textScrollViewFrameInitial;
@property(nonatomic, assign) CGFloat buttonAlphaInitial;
@property(nonatomic, assign) CGFloat topPaddingInitial;
@end

@implementation GBStageHeaderAnimation

@synthesize message;
@synthesize controller;
@synthesize headerFrame;
@synthesize headerFrameInitial;
@synthesize textScrollViewFrame;
@synthesize textScrollViewFrameInitial;
@synthesize buttonAlpha;
@synthesize buttonAlphaInitial;
@synthesize topPadding;
@synthesize topPaddingInitial;

- (void) dealloc
{
  self.message = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [super dealloc];
}

+ (GBStageHeaderAnimation*) animationWithController:(GBStageViewController*)ctrl
{
  static float duration = 0.07;
  static float frames = 10.0;
  GBStageHeaderAnimation* animation = [[[self alloc] initWithDuration:duration animationCurve:NSAnimationEaseIn] autorelease];
  animation.controller = ctrl;
  [animation setAnimationBlockingMode:NSAnimationNonblocking];
  [animation setFrameRate:MAX(frames/duration, 30.0)];
  return animation;
}

- (NSArray*) runLoopModesForAnimating
{
  return [NSArray arrayWithObject:NSRunLoopCommonModes];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress // 0.0 .. 1.0
{
  // Call super to update the progress value.
  [super setCurrentProgress:progress];
  
  float p = [self currentValue];
  
  //NSLog(@"t = %f; p = %f", (double)progress, (double)p);
  
  //NSInteger currentFrame = (NSInteger)round(progress*[self frameRate]*[self duration]);
  
  NSRect newHeaderFrame = self.headerFrame;
  NSRect newTextScrollViewFrame = self.textScrollViewFrame;
  CGFloat newButtonAlpha = self.buttonAlpha;
  
  if (progress < 0.99) // otherwise there will be just final frame sizes
  {
    newHeaderFrame.size.height = round(p*newHeaderFrame.size.height + (1.0-p)*self.headerFrameInitial.size.height);
    newTextScrollViewFrame.size.height = round(p*newTextScrollViewFrame.size.height + (1.0-p)*self.textScrollViewFrameInitial.size.height);
    CGFloat currentTopPadding = round(p*self.topPadding + (1-p)*self.topPaddingInitial);
    newTextScrollViewFrame.origin.y = newHeaderFrame.size.height - newTextScrollViewFrame.size.height - currentTopPadding;
    newButtonAlpha = p*newButtonAlpha + (1-p)*self.buttonAlphaInitial;
  }
  else
  {
    if (self.message)
    {
      [self.controller.messageTextView setString:self.message];
    }
  }


  self.controller.headerView.frame = newHeaderFrame;
  self.controller.messageTextScrollView.frame = newTextScrollViewFrame;
  //[self.controller.commitButton setAlphaValue:newButtonAlpha];
  
  if (newButtonAlpha > 0.5)
  {
    [self.controller.commitButton setHidden:NO];
  }
  else
  {
    [self.controller.commitButton setHidden:YES];
  }
  
  //if (progress > 0.99) // || (currentFrame % 2) == 0)
  {
    [self.controller.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
  }
}

- (void)startAnimation
{
  self.headerFrameInitial = self.controller.headerView.frame;
  self.textScrollViewFrameInitial = self.controller.messageTextScrollView.frame;
  
  self.topPaddingInitial = self.headerFrameInitial.size.height - self.textScrollViewFrameInitial.origin.y - self.textScrollViewFrameInitial.size.height;
  self.topPadding = self.headerFrame.size.height - self.textScrollViewFrame.origin.y - self.textScrollViewFrame.size.height;
  
  self.buttonAlphaInitial = [self.controller.commitButton isHidden] ? 0.0 : 1.0;
  
  [super startAnimation];
}

@end






