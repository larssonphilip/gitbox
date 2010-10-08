#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBModels.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "OAOptionalDelegateMessage.h"

@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localRepositoryControllers;
@synthesize delegate;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localRepositoryControllers = nil;
  [super dealloc];
}






#pragma mark Interrogation




- (NSMutableArray*) localRepositoryControllers
{
  if (!localRepositoryControllers) self.localRepositoryControllers = [NSMutableArray array];
  return [[localRepositoryControllers retain] autorelease];
}

- (GBRepositoryController*) repositoryControllerWithURL:(NSURL*)url
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    if ([[repoCtrl url] isEqual:url]) return repoCtrl;
  }
  return nil;
}

- (BOOL) isEmpty
{
  // TODO: update this when other sections are added
  return [self.localRepositoryControllers count] < 1;
}




#pragma mark Actions



- (void) updateRepositoriesPresentation
{
  NSCountedSet* allOneComponentNames = [NSCountedSet set];
  NSCountedSet* allParentNames = [NSCountedSet set];
  for (GBRepositoryController* ctrl in self.localRepositoryControllers)
  {
    [allOneComponentNames addObject:[ctrl shortNameForSourceList]];
    [allParentNames addObject:[ctrl parentFolderName]];
  }
  for (GBRepositoryController* ctrl in self.localRepositoryControllers)
  {
    ctrl.displaysTwoPathComponents = 
      ([allOneComponentNames countForObject:[ctrl shortNameForSourceList]] > 1) ||
      ([allParentNames countForObject:[ctrl parentFolderName]] > 1);
  }
  [self.localRepositoryControllers sortUsingComparator:^(GBRepositoryController* a,GBRepositoryController* b){
    return [[a nameForSourceList] compare:[b nameForSourceList]];
    //return [[[a url] path] compare:[[b url] path]];
  }];
}

- (void) addLocalRepositoryController:(GBRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  OAOptionalDelegateMessage(@selector(repositoriesControllerWillAddRepository:));
  [self.localRepositoryControllers addObject:repoCtrl];
  [self updateRepositoriesPresentation];
  [repoCtrl setNeedsUpdateEverything];
  [repoCtrl start];
  OAOptionalDelegateMessage(@selector(repositoriesControllerDidAddRepository:));
}

- (void) removeLocalRepositoryController:(GBRepositoryController*)repoCtrl
{
  if (!repoCtrl || ![self.localRepositoryControllers containsObject:repoCtrl]) return;
  OAOptionalDelegateMessage(@selector(repositoriesControllerWillRemoveRepository:));
  [repoCtrl stop];
  [self.localRepositoryControllers removeObject:repoCtrl];
  [self updateRepositoriesPresentation];
  OAOptionalDelegateMessage(@selector(repositoriesControllerDidRemoveRepository:));  
}

- (void) selectRepositoryController:(GBRepositoryController*) repoCtrl
{
  OAOptionalDelegateMessage(@selector(repositoriesControllerWillSelectRepository:));
  self.selectedRepositoryController = repoCtrl;
  OAOptionalDelegateMessage(@selector(repositoriesControllerDidSelectRepository:));
  [repoCtrl updateRepositoryIfNeeded];
  if (!repoCtrl.selectedCommit)
  {
    [repoCtrl selectCommit:repoCtrl.repository.stage];
  }
}

- (void) setNeedsUpdateEverything
{
  for (GBRepositoryController* repoCtrl in self.localRepositoryControllers)
  {
    [repoCtrl setNeedsUpdateEverything];
  }
}

- (void) beginBackgroundUpdate
{
  
}

- (void) endBackgroundUpdate
{
  
}




@end
