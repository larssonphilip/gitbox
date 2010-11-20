#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"
#import "GBModels.h"

#import "NSFileManager+OAFileManagerHelpers.h"

#import "OAObfuscatedLicenseCheck.h"

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

- (GBBaseRepositoryController*) repositoryControllerWithURL:(NSURL*)url
{
  for (GBBaseRepositoryController* repoCtrl in self.localRepositoryControllers)
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

- (GBRepositoryController*) selectedLocalRepositoryController
{
  if ([self.selectedRepositoryController isKindOfClass:[GBRepositoryController class]])
  {
    return (GBRepositoryController*) self.selectedRepositoryController;
  }
  return nil;
}

- (GBCloningRepositoryController*) selectedCloningRepositoryController
{
  if ([self.selectedRepositoryController isKindOfClass:[GBCloningRepositoryController class]])
  {
    return (GBCloningRepositoryController*) self.selectedRepositoryController;
  }
  return nil;
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

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddRepository:)]) { [self.delegate repositoriesController:self willAddRepository:repoCtrl]; }
  [self.localRepositoryControllers addObject:repoCtrl];
  [self updateRepositoriesPresentation];
  [repoCtrl setNeedsUpdateEverything];
  [repoCtrl start];
  // Updating immediately all repos altogether on the startup is heavy for the disk and CPU.
  // [repoCtrl updateRepositoryIfNeeded];
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didAddRepository:)]) { [self.delegate repositoriesController:self didAddRepository:repoCtrl]; }
}

- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl || ![self.localRepositoryControllers containsObject:repoCtrl]) return;
  
  if (repoCtrl == self.selectedRepositoryController)
  {
    [self selectRepositoryController:nil];
  }
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willRemoveRepository:)]) { [self.delegate repositoriesController:self willRemoveRepository:repoCtrl]; }
  [repoCtrl stop];
  [self.localRepositoryControllers removeObject:repoCtrl];
  [self updateRepositoriesPresentation];
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didRemoveRepository:)]) { [self.delegate repositoriesController:self didRemoveRepository:repoCtrl]; }
}

- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl
{
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willSelectRepository:)]) { [self.delegate repositoriesController:self willSelectRepository:repoCtrl]; }
  self.selectedRepositoryController = repoCtrl;
  [repoCtrl updateRepositoryIfNeeded];
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didSelectRepository:)]) { [self.delegate repositoriesController:self didSelectRepository:repoCtrl]; }
  [self.selectedRepositoryController didSelect];
}

- (void) setNeedsUpdateEverything
{
  for (GBBaseRepositoryController* repoCtrl in self.localRepositoryControllers)
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
