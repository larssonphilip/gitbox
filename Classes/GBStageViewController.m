#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBStageViewController.h"
#import "GBFileEditingController.h"
#import "GBCommitPromptController.h"
#import "GBUserNameEmailController.h"

#import "NSObject+OAKeyValueObserving.h"
#import "NSArray+OAArrayHelpers.h"

@interface GBStageViewController ()
@property(nonatomic, retain) GBCommitPromptController* commitPromptController;
@property(nonatomic, retain) NSIndexSet* rememberedSelectionIndexes;
@property(nonatomic, assign) BOOL alreadyCheckedUserNameAndEmail;
- (void) checkUserNameAndEmailIfNeededWithBlock:(void(^)())block;
@end



@implementation GBStageViewController

@synthesize stage;
//@synthesize messageTextField;
@synthesize messageTextView;
@synthesize commitPromptController;
@synthesize rememberedSelectionIndexes;

@synthesize alreadyCheckedUserNameAndEmail;

#pragma mark Init

- (void) dealloc
{
  self.stage = nil;
  //self.messageTextField = nil;
  self.messageTextView = nil;
  self.commitPromptController = nil;
  self.rememberedSelectionIndexes = nil;
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



- (IBAction) commit:(id)sender
{
  [self checkUserNameAndEmailIfNeededWithBlock:^{
    [self.repositoryController stageChanges:[self selectedChanges] withBlock:^{
      
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
    }];
  }];
}


- (BOOL) validateCommit:(id)sender
{
  return [self.stage isCommitable];
}












#pragma mark NSTextFieldDelegate

/*
// Since the textfield resigns first responder as soon as it becomes it, 
// we don't rely on any resign notification from it. 
// Instead, we will do appropriate updates when something else becomes first responder.
- (void) textField:(NSTextField*)aTextField willBecomeFirstResponder:(BOOL)result
{
  //NSLog(@"become first responder: %@; message: %@", aTextField, self.messageTextField);
  self.rememberedSelectionIndexes = [self.statusArrayController selectionIndexes];
  [self.statusArrayController setSelectionIndexes:[NSIndexSet indexSet]];
}

- (void) textField:(NSTextField*)aTextField didCancel:(id)sender
{
  //NSLog(@"Cancel hit at %@", sender);
  if (self.rememberedSelectionIndexes)
  {
    [self.statusArrayController setSelectionIndexes:self.rememberedSelectionIndexes];
  }
  [[self.tableView window] makeFirstResponder:self.tableView];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
  NSLog(@"editing...");
  return YES;
}
*/





#pragma mark NSTextViewDelegate


- (void) textView:(NSTextView*)aTextView willBecomeFirstResponder:(BOOL)result
{
  if (!result) return;
  self.rememberedSelectionIndexes = [self.statusArrayController selectionIndexes];
  [self.statusArrayController setSelectionIndexes:[NSIndexSet indexSet]];
  
  NSLog(@"TODO: animate to the ready state");
}

- (void) textView:(NSTextView*)aTextView willResignFirstResponder:(BOOL)result
{
  if (!result) return;
  NSLog(@"TODO: if the message is not empty, adjust layout back to the idle state");
}

- (void) textView:(NSTextView*)aTextView didCancel:(id)sender
{
  if (self.rememberedSelectionIndexes)
  {
    [self.statusArrayController setSelectionIndexes:self.rememberedSelectionIndexes];
  }
  [[self.tableView window] makeFirstResponder:self.tableView];
}

- (void)textDidChange:(NSNotification *)aNotification
{
  NSLog(@"TODO: check the message size and adjust layout");
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
  NSArray* items = [[self.changes objectsAtIndexes:indexSet] valueForKey:@"pasteboardItem"];
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
