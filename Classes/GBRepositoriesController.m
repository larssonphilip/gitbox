#import "GBRepositoriesController.h"
#import "GBRepositoryController.h"
#import "GBCloningRepositoryController.h"
#import "GBModels.h"

#import "NSFileManager+OAFileManagerHelpers.h"

#import "OALicenseNumberCheck.h"
#import "OAObfuscatedLicenseCheck.h"
#import "OABlockQueue.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBRepositoriesController

@synthesize selectedRepositoryController;
@synthesize localRepositoryControllers;
@synthesize localRepositoriesUpdatesQueue;
@synthesize delegate;

- (void) dealloc
{
  self.selectedRepositoryController = nil;
  self.localRepositoryControllers = nil;
  self.localRepositoriesUpdatesQueue = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.localRepositoriesUpdatesQueue = [[OABlockQueue new] autorelease];
    self.localRepositoriesUpdatesQueue.maxConcurrentOperationCount = 4;
  }
  return self;
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


- (BOOL) tryOpenLocalRepositoryAtURL:(NSURL*)aURL
{
  NSString* aPath = [aURL path];

  BOOL isDirectory = NO;
  if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory])
  {
    [NSAlert message:NSLocalizedString(@"File not found.", @"") description:aPath];
    return NO; 
  }
  
  if (!isDirectory)
  {
    while (![NSFileManager isReadableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]])
    {
      if (!aPath || [aPath isEqualToString:@"/"] || [aPath isEqualToString:@""])
      {
        return NO;
      }
      aPath = [aPath stringByDeletingLastPathComponent];
      if (!aPath || [aPath isEqualToString:@""] || [aPath isEqualToString:@"/"])
      {
        return NO;
      }
    }
    aURL = [NSURL fileURLWithPath:aPath];
  }
  
  NSString* validPath = [GBRepository validRepositoryPathForPath:aPath];
  
  if (validPath)
  {
    [self openLocalRepositoryAtURL:[NSURL fileURLWithPath:validPath]];
    return YES;
  }
  
  if (![NSFileManager isWritableDirectoryAtPath:aPath])
  {
    [NSAlert message:NSLocalizedString(@"No write access to the folder.", @"") description:aPath];
    return NO;
  }
  
  if ([NSAlert prompt:NSLocalizedString(@"The folder is not a git repository.\nMake it a repository?", @"App")
          description:aPath])
  {
    [GBRepository initRepositoryAtURL:aURL];
    [self openLocalRepositoryAtURL:aURL];
    return YES;
  }
  
  return NO;
}



- (void) openLocalRepositoryAtURL:(NSURL*)url
{
  GBBaseRepositoryController* repoCtrl = [self repositoryControllerWithURL:url];
  if (!repoCtrl)
  {
#if GITBOX_APP_STORE
#else
    if ([self.localRepositoryControllers count] >= 1)
    {
      NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
      if (!OAValidateLicenseNumber(license))
      {
        [NSApp tryToPerform:@selector(showLicense:) with:self];
        
        NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:@"license"];
        if (!OAValidateLicenseNumber(license))
        {
          return;
        }
      }
    }
#endif
    
    repoCtrl = [GBRepositoryController repositoryControllerWithURL:url];
    if (repoCtrl)
    {
      [self addLocalRepositoryController:repoCtrl];
      [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
    }
  }
  [self selectRepositoryController:repoCtrl];
}







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
    return [[a nameForSourceList] localizedCaseInsensitiveCompare:[b nameForSourceList]];
    //return [[[a url] path] compare:[[b url] path]];
  }];
}

- (void) addLocalRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  if (!repoCtrl) return;
  if ([self.localRepositoryControllers containsObject:repoCtrl]) return;
  if ([self.delegate respondsToSelector:@selector(repositoriesController:willAddRepository:)]) { [self.delegate repositoriesController:self willAddRepository:repoCtrl]; }
  [self.localRepositoryControllers addObject:repoCtrl];
  [self updateRepositoriesPresentation];
  
  repoCtrl.updatesQueue = self.localRepositoriesUpdatesQueue;
  
  [repoCtrl start];

  [repoCtrl updateQueued];

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
  
  if ([self.delegate respondsToSelector:@selector(repositoriesController:didSelectRepository:)]) { [self.delegate repositoriesController:self didSelectRepository:repoCtrl]; }
  [self.selectedRepositoryController didSelect];
}

- (void) beginBackgroundUpdate
{
  
}

- (void) endBackgroundUpdate
{
  
}




@end
