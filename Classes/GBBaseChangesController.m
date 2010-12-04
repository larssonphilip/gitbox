#import "GBModels.h"
#import "GBBaseChangesController.h"
#import "NSObject+OADispatchItemValidation.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBBaseChangesController

@synthesize tableView;
@synthesize statusArrayController;
@synthesize repositoryController;
@synthesize changes;

#pragma mark Init

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.tableView = nil;
  self.statusArrayController = nil;
  self.repositoryController = nil;
  self.changes = nil;
  [super dealloc];
}


#pragma mark Interrogation

- (NSArray*) selectedChanges
{
  NSInteger clickedRow = [self.tableView clickedRow];
  if (clickedRow < 0)
  {
    return [self.statusArrayController selectedObjects];
  }
  else
  {
    // if clicked item is contained in selected objects, we take the selection
    GBChange* clickedChange = [self.changes objectAtIndex:(NSUInteger)clickedRow];
    NSArray* selectedChanges = [self.statusArrayController selectedObjects];
    if ([selectedChanges containsObject:clickedChange])
    {
      return selectedChanges;
    }
    else
    {
      return [NSArray arrayWithObject:clickedChange];
    }
  }
}

- (NSWindow*) window
{
  return [[self view] window];
}


#pragma mark Update


- (void) update
{
  for (GBChange* change in self.changes)
  {
    [change update];
  }
}




#pragma mark NSTableViewDelegate






#pragma mark Actions

// TODO: modify to work with multiple changes


- (IBAction) stageShowDifference:_
{
  [[[[self selectedChanges] firstObject] nilIfBusy] launchDiffWithBlock:^{
    
  }];
}
  - (BOOL) validateStageShowDifference:_
  {
    if ([[self selectedChanges] count] != 1) return NO;
    return [[[[self selectedChanges] firstObject] nilIfBusy] validateShowDifference];
  }


- (IBAction) stageRevealInFinder:_
{
  [[[[self selectedChanges] firstObject] nilIfBusy] revealInFinder];
}
  - (BOOL) validateStageRevealInFinder:_
  {
    if ([[self selectedChanges] count] != 1) return NO;
    return [[[[self selectedChanges] firstObject] nilIfBusy] validateRevealInFinder];
  }


- (IBAction) selectLeftPane:_
{
  [[self.tableView window] selectKeyViewPrecedingView:self.tableView];
}

- (IBAction) selectFirstLineIfNeeded:_
{
  if (![[self selectedChanges] firstObject])
  {
    [self.statusArrayController selectNext:_];
  }
}



#pragma mark Actions Validation


// For each action selector "doSomething:" redirects call to "validateDoSomething:"
// If the selector is not implemented, returns YES.
- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
  return [self dispatchUserInterfaceItemValidation:anItem];
}



@end
