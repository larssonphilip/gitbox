#import "GBRepository.h"
#import "GBRepositoryBranchesAndTagsController.h"

@interface GBRepositoryBranchesAndTagsController ()
@end

@implementation GBRepositoryBranchesAndTagsController

@synthesize branchesBinding;
@synthesize tagsBinding;

@synthesize branchesController;
@synthesize tagsController;

@synthesize deleteBranchButton;
@synthesize deleteTagButton;

- (void) dealloc
{
  [branchesBinding release]; branchesBinding = nil;
  [tagsBinding release]; tagsBinding = nil;
  [branchesController release]; branchesController = nil;
  [tagsController release]; tagsController = nil;
  [deleteBranchButton release]; deleteBranchButton = nil;
  [deleteTagButton release]; deleteTagButton = nil;
  [super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
  if ((self = [super initWithRepository:repo]))
  {
    self.branchesBinding = [NSMutableArray array];
    self.tagsBinding = [NSMutableArray array];
  }
  return self;
}

- (NSString*) title
{
  return NSLocalizedString(@"Branches and Tags", @"");
}

- (void) updateButtonTitles
{
  if ([[self.branchesController selectedObjects] count] < 2)
  {
    [self.deleteBranchButton setTitle:NSLocalizedString(@"  Delete Branch...", @"GBSettings")];
  }
  else
  {
    [self.deleteBranchButton setTitle:NSLocalizedString(@"  Delete Branches...", @"GBSettings")];
  }
  
  if ([[self.tagsController selectedObjects] count] < 2)
  {
    [self.deleteTagButton setTitle:NSLocalizedString(@"  Delete Tag...", @"GBSettings")];
  }
  else
  {
    [self.deleteTagButton setTitle:NSLocalizedString(@"  Delete Tags...", @"GBSettings")];
  }
}

- (void) viewDidAppear
{
  [super viewDidAppear];
  
  self.branchesBinding = [[[self.repository localBranches] mutableCopy] autorelease];
  self.tagsBinding = [[[self.repository tags] mutableCopy] autorelease];
  
  [self updateButtonTitles];
}

- (IBAction) deleteBranch:(id)sender
{
  // TODO: support undo + show the undo button
  int c = [[self.branchesController selectedObjects] count];
  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Delete %d branches?", @"GBSettings"), c];
  if (c == 1)
  {
    message = [NSString stringWithFormat:NSLocalizedString(@"Delete branch “%@”?", @"GBSettings"), [[[self.branchesController selectedObjects] objectAtIndex:0] name]];
  }
  [self criticalConfirmationWithMessage:message
                            description:NSLocalizedString(@"You cannot undo this action.", @"GBSettings") 
                                     ok:NSLocalizedString(@"Delete", @"GBSettings") 
                             completion:^(BOOL result){
                               if (!result) return;
                               [self.repository removeRefs:[self.branchesController selectedObjects] withBlock:^{}];
                               [self.branchesController remove:sender];
                             }];
}

- (IBAction) deleteTag:(id)sender
{
  int c = [[self.tagsController selectedObjects] count];
  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Delete %d tags?", @"GBSettings"), c];
  if (c == 1)
  {
    message = [NSString stringWithFormat:NSLocalizedString(@"Delete tag “%@”?", @"GBSettings"), [[[self.tagsController selectedObjects] objectAtIndex:0] name]];
  }
  [self criticalConfirmationWithMessage:message
                            description:NSLocalizedString(@"You cannot undo this action.", @"GBSettings") 
                                     ok:NSLocalizedString(@"Delete", @"GBSettings") 
                             completion:^(BOOL result){
                               if (!result) return;
                               [self.repository removeRefs:[self.tagsController selectedObjects] withBlock:^{}];
                               [self.tagsController remove:sender];
                             }];
  
}



#pragma mark NSTableViewDelegate


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  // TODO: rename the buttons to plural/singular
  [self updateButtonTitles];
}


@end
