#import "GBModels.h"

#import "ObsoleteGBRepositoryController.h"
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

@implementation ObsoleteGBRepositoryController

@synthesize repositoryURL;
@synthesize repository;

@synthesize commandsController;

@synthesize splitView;






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
  return NO;
}







#pragma mark GBRepositoryDelegate


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
