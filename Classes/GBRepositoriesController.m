#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"
#import "GBModels.h"

#import "NSFileManager+OAFileManagerHelpers.h"

GBNotificationDefine(GBRepositoriesControllerWillAddRepository);
GBNotificationDefine(GBRepositoriesControllerDidAddRepository);
GBNotificationDefine(GBRepositoriesControllerWillRemoveRepository);
GBNotificationDefine(GBRepositoriesControllerDidRemoveRepository);
GBNotificationDefine(GBRepositoriesControllerWillSelectRepository);
GBNotificationDefine(GBRepositoriesControllerDidSelectRepository);
GBNotificationDefine(GBRepositoriesControllerDidSelectLocalRepository);
GBNotificationDefine(GBRepositoriesControllerDidSelectCloningRepository);


@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localRepositoryControllers;

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
  GBNotificationSend(GBRepositoriesControllerWillAddRepository);
  [self.localRepositoryControllers addObject:repoCtrl];
  [self updateRepositoriesPresentation];
  [repoCtrl setNeedsUpdateEverything];
  [repoCtrl start];
  GBNotificationSend(GBRepositoriesControllerDidAddRepository);
}

- (void) removeLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl || ![self.localRepositoryControllers containsObject:repoCtrl]) return;
  GBNotificationSend(GBRepositoriesControllerWillRemoveRepository);
  [repoCtrl stop];
  [self.localRepositoryControllers removeObject:repoCtrl];
  [self updateRepositoriesPresentation];
  GBNotificationSend(GBRepositoriesControllerDidRemoveRepository);
}

- (void) selectRepositoryController:(GBBaseRepositoryController*) repoCtrl
{
  GBNotificationSend(GBRepositoriesControllerWillSelectRepository);
  self.selectedRepositoryController = repoCtrl;
  GBNotificationSend(GBRepositoriesControllerDidSelectRepository);
  if ([self selectedLocalRepositoryController])
  {
    GBNotificationSend(GBRepositoriesControllerDidSelectLocalRepository);
  }
  else if ([self selectedCloningRepositoryController])
  {
    GBNotificationSend(GBRepositoriesControllerDidSelectCloningRepository);
  }
  [repoCtrl updateRepositoryIfNeeded];
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
