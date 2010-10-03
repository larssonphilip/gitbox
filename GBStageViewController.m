#import "GBModels.h"

#import "GBRepositoryController.h"
#import "GBStageViewController.h"
#import "GBFileEditingController.h"
#import "GBCommitPromptController.h"

#import "NSObject+OAKeyValueObserving.h"
#import "NSArray+OAArrayHelpers.h"


@implementation GBStageViewController

@synthesize stage;
@synthesize commitPromptController;

#pragma mark Init

- (void) dealloc
{
  self.stage = nil;
  self.commitPromptController = nil;
  [super dealloc];
}


- (void) update
{
  [super update];
  for (GBChange* change in self.changes)
  {
    change.delegate = self.repositoryController;
  }
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


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder:sender];
}




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
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
  [alert setMessageText:NSLocalizedString(@"Revert selected files to last committed state?", @"Stage")];
  [alert setInformativeText:NSLocalizedString(@"All non-committed changes will be lost.",@"Stage")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(stageRevertFileAlertDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}
- (BOOL) validateStageRevertFile:(id)sender
{
  // returns YES when non-empty and array has something to revert
  return ![[self selectedChanges] allAreTrue:@selector(isUntrackedFile)]; 
}

- (void) stageRevertFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn)
  {
    [self.repositoryController revertChanges:[self selectedChanges]];
  }
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
                      contextInfo:nil];  
}

- (BOOL) validateStageDeleteFile:(id)sender
{
  // returns YES when non-empty and array has something to delete
  if ([[self selectedChanges] allAreTrue:@selector(isDeletedFile)]) return NO;
  if ([[self selectedChanges] allAreTrue:@selector(staged)]) return NO;
  return YES;
}

- (void) stageDeleteFileAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
  if (returnCode == NSAlertFirstButtonReturn)
  {
    [self.repositoryController deleteFilesInChanges:[self selectedChanges]];
  }
  [NSApp endSheet:[self window]];
  [[alert window] orderOut:self];
  [alert autorelease];
}



- (IBAction) commit:(id)sender
{
  [self.repositoryController stageChanges:[self selectedChanges] withBlock:^{
    
    if (!self.commitPromptController)
    {
      self.commitPromptController = [GBCommitPromptController controller];
    }
    
    GBCommitPromptController* prompt = self.commitPromptController;
    GBRepositoryController* repoCtrl = self.repositoryController;
    
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
}


- (BOOL) validateCommit:(id)sender
{
  return [self.stage isCommitable];
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

// This avoid changing selection when checkbox is clicked.
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  NSEvent *currentEvent = [[aTableView window] currentEvent];
  if([currentEvent type] != NSLeftMouseDown) return YES;
  // you may also check for the NSLeftMouseDragged event
  // (changing the selection by holding down the mouse button and moving the mouse over another row)
  int columnIndex = [aTableView columnAtPoint:[aTableView convertPoint:[currentEvent locationInWindow] fromView:nil]];
  return !(columnIndex == 0);
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self.repositoryController selectCommitableChanges:[self selectedChanges]];
}


@end
