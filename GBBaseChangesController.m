#import "GBModels.h"
#import "GBBaseChangesController.h"

@implementation GBBaseChangesController

@synthesize repository;
@synthesize tableView;
@synthesize statusArrayController; 


#pragma mark Init

- (void) dealloc
{
  self.repository = nil;
  self.tableView = nil;
  self.statusArrayController = nil;
  [super dealloc];
}


#pragma mark Interrogation

- (NSArray*) selectedChanges
{
  // TODO: return objects based on currently selected indexes
  return [self.statusArrayController selectedObjects];
}

- (NSWindow*) window
{
  return [[self view] window];
}


#pragma mark NSTableViewDelegate



@end
