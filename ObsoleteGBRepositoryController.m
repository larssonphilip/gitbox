#import "GBModels.h"

#import "ObsoleteGBRepositoryController.h"
#import "GBHistoryViewController.h"
#import "GBStageViewController.h"
#import "GBCommitViewController.h"

#import "GBAppDelegate.h"
#import "GBRemotesController.h"
#import "GBPromptController.h"
#import "GBCommitPromptController.h"
#import "GBFileEditingController.h"
#import "GBCommandsController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSMenu+OAMenuHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSObject+OADispatchItemValidation.h"

#import <objc/runtime.h>

@implementation ObsoleteGBRepositoryController

@synthesize repositoryURL;
@synthesize repository;

@synthesize delegate;

@synthesize historyController;
@synthesize changesViewController;
@synthesize stageController;
@synthesize commitController;
@synthesize commitPromptController;
@synthesize commandsController;

@synthesize splitView;

@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize remoteBranchPopUpButton;



#pragma mark Init

- (GBCommitViewController*) commitController
{
  if (!commitController)
  {
    self.commitController = [[[GBCommitViewController alloc] initWithNibName:@"GBCommitViewController" bundle:nil] autorelease];
//    commitController.repository = self.repository;
  }
  return [[commitController retain] autorelease];
}

- (GBCommitPromptController*) commitPromptController
{
  if (!commitPromptController)
  {
    self.commitPromptController = [GBCommitPromptController controller];
//    commitPromptController.repository = self.repository;
//    commitPromptController.target = self;
//    commitPromptController.finishSelector = @selector(doneCommit:);
  }
  return [[commitPromptController retain] autorelease];
}

- (GBCommandsController*) commandsController
{
  if (!commandsController)
  {
    self.commandsController = [GBCommandsController controller];
    
  }
  return [[commandsController retain] autorelease];
}


#pragma mark Interrogation











#pragma mark Git Actions




- (IBAction) createNewRemoteBranch:(id)sender
{
  // Usually, new remote branch is created for the new local branch,
  // so we should use local branch name as a default value.
  GBRemote* remote = [sender representedObject];
  NSString* defaultName = [self.repository.currentLocalRef.name 
                           uniqueStringForStrings:[remote.branches valueForKey:@"name"]];

  GBPromptController* ctrl = [GBPromptController controller];
  
  ctrl.title = NSLocalizedString(@"New Remote Branch", @"");
  ctrl.promptText = NSLocalizedString(@"Branch Name:", @"");
  ctrl.buttonText = NSLocalizedString(@"OK", @"");
  ctrl.requireStripWhitespace = YES;
  ctrl.value = defaultName;
  
//  ctrl.target = self;
//  ctrl.finishSelector = @selector(doneChoosingNameForNewRemoteBranch:);
  
//  ctrl.payload = [sender representedObject]; // GBRemote passed from menu item
  [ctrl runSheetInWindow:[self window]];
}

  - (void) doneChoosingNameForNewRemoteBranch:(GBPromptController*)ctrl
  {
    GBRemote* remote = nil ; //ctrl.payload;
    
    GBRef* remoteBranch = [[GBRef new] autorelease];
    remoteBranch.repository = self.repository;
    remoteBranch.name = ctrl.value;
    remoteBranch.remoteAlias = remote.alias;
    remoteBranch.isNewRemoteBranch = YES;
    [remote addBranch:remoteBranch];
    
//    [self.repository selectRemoteBranch:remoteBranch];
    //[self updateBranchMenus];
  }

- (IBAction) createNewRemote:(id)sender
{
  [self editRepositories:sender];
}


//- (IBAction) commit:(id)sender
//{
//  BOOL delayPrompt = [[self.stageController selectedChanges] count] > 0; 
//  [self.stageController stageDoStage:sender];
//  if (delayPrompt)
//  {
//    [self.commitPromptController performSelector:@selector(runSheetInWindow:) 
//                                      withObject:[self window] 
//                                      afterDelay:0.3];
//  }
//  else
//  {
//    [self.commitPromptController runSheetInWindow:[self window]];
//  }
//}
//
//  - (void) doneCommit:(GBPromptController*)ctrl
//  {
//    [self.repository commitWithMessage:ctrl.value];
//  }










#pragma mark View Actions



- (IBAction) toggleSplitViewOrientation:(NSMenuItem*)sender
{
  [self.splitView setVertical:![self.splitView isVertical]];
  [self.splitView adjustSubviews];
  if ([self.splitView isVertical])
  {
    [sender setTitle:NSLocalizedString(@"Horizontal Views",@"")];
  }
  else
  {
    [sender setTitle:NSLocalizedString(@"Vertical Views",@"")];
  }
}

- (IBAction) editRepositories:(id)sender
{
  GBRemotesController* remotesController = [GBRemotesController controller];
  
  remotesController.repository = self.repository;
  remotesController.target = self;
  remotesController.finishSelector = @selector(doneEditRepositories:);
  remotesController.cancelSelector = @selector(cancelledEditRepositories:);
  
  [self beginSheetForController:remotesController];
}

  - (void) doneEditRepositories:(GBRemotesController*)remotesController
  {
//    [self updateBranchMenus];
//    [self.repository reloadCommits];
    [self endSheetForController:remotesController];
  }

  - (void) cancelledEditRepositories:(GBRemotesController*)remotesController
  {
    [self endSheetForController:remotesController];
  }


- (IBAction) editGitIgnore:(id)sender
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".gitignore";
  fileEditor.URL = [self.repository.url URLByAppendingPathComponent:@".gitignore"];
  [fileEditor runSheetInWindow:[self window]];
}

- (IBAction) editGitConfig:(id)sender
{
  GBFileEditingController* fileEditor = [GBFileEditingController controller];
  fileEditor.title = @".git/config";
  fileEditor.URL = [self.repository.url URLByAppendingPathComponent:@".git/config"];
  [fileEditor runSheetInWindow:[self window]];
}

- (IBAction) openInTerminal:(id)sender
{ 
  NSString* s = [NSString stringWithFormat:
                 @"tell application \"Terminal\" to do script \"cd %@\"", self.repository.path];
  
  NSAppleScript* as = [[[NSAppleScript alloc] initWithSource: s] autorelease];
  [as executeAndReturnError:nil];
}

- (IBAction) openInFinder:(id)sender
{
  [[NSWorkspace sharedWorkspace] openFile:self.repository.path];
}




#pragma mark Command menu


- (IBAction) commandMenuItem:(id)sender
{
  // empty action to make validations work
}






#pragma mark Actions Validation



// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(NSObject<NSValidatedUserInterfaceItem>*)anItem
{
  if ([anItem isKindOfClass:[NSMenuItem class]])
  {
    NSMenuItem* menuItem = (NSMenuItem*)anItem;
    if ([menuItem tag] == 500) // Command menu item
    {
      NSMenu* menu = [menuItem submenu];
      [menu removeAllItems];
      
      NSMenuItem* commandItem = [[[NSMenuItem alloc] initWithTitle:@"Some Command" 
                                                            action:@selector(doCommand:)
                                                     keyEquivalent:@"1"] autorelease];
      [commandItem setKeyEquivalentModifierMask:NSCommandKeyMask];
      [menu addItem:commandItem];
      
      [menuItem setSubmenu:menu];
      return YES;
    }
  }
  
  // FIXME: this should in fact be a bit smarter: should use nextResponder instead of hard-coded subviews,
  //        also should return NO for the selectors which are not implemented
  return [self dispatchUserInterfaceItemValidation:anItem] ||
         [self.historyController validateUserInterfaceItem:anItem] ||
         [self.changesViewController validateUserInterfaceItem:anItem];
}







#pragma mark GBRepositoryDelegate




- (void) selectedCommitDidChange:(GBCommit*) aCommit
{
  if ([aCommit isStage])
  {
    self.changesViewController = self.stageController;
  }
  else
  {
    self.changesViewController = self.commitController;
  }
  NSView* changesPlaceholderView = [[self.splitView subviews] objectAtIndex:2];
  [self.changesViewController loadInView:changesPlaceholderView];
}

- (void) repository:(GBRepository*)repo alertWithError:(NSError*)error
{
//  [self repository:repo alertWithMessage:[error localizedDescription] description:@""];
}

- (void) repository:(GBRepository*)repo alertWithMessage:(NSString*)message description:(NSString*)description
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:message];
  [alert setInformativeText:description];
  [alert setAlertStyle:NSWarningAlertStyle];
  
  [alert runModal];
  
  //[alert retain];
  // This cycle delay helps to avoid toolbar deadlock
  //[self performSelector:@selector(slideAlert:) withObject:alert afterDelay:0.1];
}

  - (void) slideAlert:(NSAlert*)alert
  {
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(repositoryErrorAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
  }

  - (void) repositoryErrorAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
  {
    [NSApp endSheet:[self window]];
    [[alert window] orderOut:self];
    [alert autorelease];
  }












@end
