#import "GBRepository.h"
#import "GBRepositoryBranchesAndTagsController.h"

@interface GBRepositoryBranchesAndTagsController ()

@property(nonatomic, retain) NSMutableArray* branchesToDelete;
@property(nonatomic, retain) NSMutableArray* tagsToDelete;

@end

@implementation GBRepositoryBranchesAndTagsController

@synthesize branchesBinding;
@synthesize tagsBinding;

@synthesize branchesController;
@synthesize tagsController;

@synthesize deleteBranchButton;
@synthesize deleteTagButton;

@synthesize branchesToDelete;
@synthesize tagsToDelete;

- (void) dealloc
{
  [branchesBinding release]; branchesBinding = nil;
  [tagsBinding release]; tagsBinding = nil;
  [branchesController release]; branchesController = nil;
  [tagsController release]; tagsController = nil;
  [deleteBranchButton release]; deleteBranchButton = nil;
  [deleteTagButton release]; deleteTagButton = nil;
  [branchesToDelete release]; branchesToDelete = nil;
  [tagsToDelete release]; tagsToDelete = nil;
  
  [super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
  if ((self = [super initWithRepository:repo]))
  {
    self.branchesBinding = [NSMutableArray array];
    self.tagsBinding = [NSMutableArray array];
    
    self.branchesToDelete = [NSMutableArray array];
    self.tagsToDelete = [NSMutableArray array];
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

- (void) cancel
{
  self.branchesToDelete = [NSMutableArray array];
  self.tagsToDelete = [NSMutableArray array];
}

- (void) save
{
  [self.repository removeRefs:[self.branchesToDelete arrayByAddingObjectsFromArray:self.tagsToDelete] withBlock:^{
    self.branchesToDelete = [NSMutableArray array];
    self.tagsToDelete = [NSMutableArray array];
  }];
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
  self.dirty = YES;
  [self.branchesToDelete addObjectsFromArray:[self.branchesController selectedObjects]];
  [self.branchesController remove:sender];
  
//#if 0
//  int c = [[self.branchesController selectedObjects] count];
//  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Delete %d branches?", @"GBSettings"), c];
//  if (c == 1)
//  {
//    message = [NSString stringWithFormat:NSLocalizedString(@"Delete branch “%@”?", @"GBSettings"), [[[self.branchesController selectedObjects] objectAtIndex:0] name]];
//  }
//  [self criticalConfirmationWithMessage:message
//                            description:NSLocalizedString(@"You cannot undo this action.", @"GBSettings") 
//                                     ok:NSLocalizedString(@"Delete", @"GBSettings") 
//                             completion:^(BOOL result){
//                               if (!result) return;
//                               [self.repository removeRefs:[self.branchesController selectedObjects] withBlock:^{}];
//                               [self.branchesController remove:sender];
//                             }];
//#endif
}

- (IBAction) deleteTag:(id)sender
{
  self.dirty = YES;
  [self.tagsToDelete addObjectsFromArray:[self.tagsController selectedObjects]];
  [self.tagsController remove:sender];

//#if 0
//  int c = [[self.tagsController selectedObjects] count];
//  NSString* message = [NSString stringWithFormat:NSLocalizedString(@"Delete %d tags?", @"GBSettings"), c];
//  if (c == 1)
//  {
//    message = [NSString stringWithFormat:NSLocalizedString(@"Delete tag “%@”?", @"GBSettings"), [[[self.tagsController selectedObjects] objectAtIndex:0] name]];
//  }
//  [self criticalConfirmationWithMessage:message
//                            description:NSLocalizedString(@"You cannot undo this action.", @"GBSettings") 
//                                     ok:NSLocalizedString(@"Delete", @"GBSettings") 
//                             completion:^(BOOL result){
//                               if (!result) return;
//                               [self.repository removeRefs:[self.tagsController selectedObjects] withBlock:^{}];
//                               [self.tagsController remove:sender];
//                             }];
//#endif
}



#pragma mark NSTableViewDelegate


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  // TODO: rename the buttons to plural/singular
  [self updateButtonTitles];
}


@end
