#import "GBRepository.h"
#import "GBRepositoryBranchesAndTagsController.h"

@interface GBRepositoryBranchesAndTagsController ()
@end

@implementation GBRepositoryBranchesAndTagsController

@synthesize branchesBinding;
@synthesize tagsBinding;

@synthesize branchesController;
@synthesize tagsController;

- (void) dealloc
{
  [branchesBinding release]; branchesBinding = nil;
  [tagsBinding release]; tagsBinding = nil;
  [branchesController release]; branchesController = nil;
  [tagsController release]; tagsController = nil;
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

- (void) viewDidAppear
{
  [super viewDidAppear];
  
  self.branchesBinding = [[[self.repository localBranches] mutableCopy] autorelease];
  self.tagsBinding = [[[self.repository tags] mutableCopy] autorelease];
}

- (IBAction) deleteBranch:(id)sender
{
  [self.repository removeRefs:[self.branchesController selectedObjects] withBlock:^{}];
  [self.branchesController remove:sender];
}

- (IBAction) deleteTag:(id)sender
{
  [self.repository removeRefs:[self.tagsController selectedObjects] withBlock:^{}];
  [self.tagsController remove:sender];
}


@end
