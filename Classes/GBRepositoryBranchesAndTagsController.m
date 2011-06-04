#import "GBRepositoryBranchesAndTagsController.h"

@interface GBRepositoryBranchesAndTagsController ()
@end

@implementation GBRepositoryBranchesAndTagsController

@synthesize branchesBinding;
@synthesize tagsBinding;

- (void) dealloc
{
  [branchesBinding release]; branchesBinding = nil;
  [tagsBinding release]; tagsBinding = nil;
  [super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
  if ((self = [super initWithRepository:repo]))
  {
  }
  return self;
}

- (NSString*) title
{
  return NSLocalizedString(@"Branches and Tags", @"");
}

- (IBAction) deleteBranch:(id)sender
{
  
}

- (IBAction) deleteTag:(id)sender
{
  
}


@end
