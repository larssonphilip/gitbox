#import "GBCloneWindowController.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBCloneWindowController

@synthesize urlField;
@synthesize folderPopUpButton;
@synthesize cloneButton;
@synthesize finishBlock;
@synthesize remoteURL;
@synthesize folderURL;

@synthesize windowHoldingSheet;

- (void) dealloc
{
  self.urlField = nil;
  self.folderPopUpButton = nil;
  self.cloneButton = nil;
  self.finishBlock = nil;
  self.remoteURL = nil;
  self.folderURL = nil;
  [super dealloc];
}

- (void) update
{
}

- (IBAction) cancel:_
{
  if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
}

- (IBAction) ok:_
{
  NSString* urlString = [self.urlField stringValue];
  if ([urlString rangeOfString:@"://"].location == NSNotFound)
  {
    urlString = [NSString stringWithFormat:@"ssh://%@", urlString];
  }
  self.remoteURL = [NSURL URLWithString:urlString];
  self.folderURL = (NSURL*)[[self.folderPopUpButton selectedItem] representedObject];
  
  if (self.folderURL && self.remoteURL)
  {
    if (self.finishBlock) self.finishBlock();
  }
  
  // clean up for later use
  self.remoteURL = nil;
  self.folderURL = nil;
  
  if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
}


- (void) selectFolder:_
{
  if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
  
  //  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  //  openPanel.allowsMultipleSelection = NO;
  //  openPanel.canChooseFiles = NO;
  //  openPanel.canChooseDirectories = YES;
  //  [openPanel setAccessoryView:self.cloneAccessoryView];
  //  [openPanel beginSheetModalForWindow:[self.windowController window] completionHandler:^(NSInteger result){
  //    if (result == NSFileHandlingPanelOKButton)
  //    {
  //      NSURL* destinationFolderURL = [[openPanel URLs] objectAtIndex:0];
  //      
  //      
  ////        repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
  ////        [self.repositoriesController addLocalRepositoryController:repoCtrl];
  ////        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
  //      
  //      
  //      NSLog(@"TODO: add a GBCloningRepositoryController to the local repository controllers");
  //    }
  //    if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
  //  }];
}


- (void) windowDidLoad
{
  [super windowDidLoad];
  [self update];
}


- (void) runSheetInWindow:(NSWindow*)aWindow
{
  self.windowHoldingSheet = aWindow;
  [aWindow beginSheetForController:self];
}



@end
