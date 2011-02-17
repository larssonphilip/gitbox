#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"
#import "GBSubmoduleCell.h"
#import "GBRepositoryController.h"

NSString* const GBSubmoduleStatusNotCloned = @"GBSubmoduleStatusNotCloned";
NSString* const GBSubmoduleStatusUpToDate = @"GBSubmoduleStatusUpToDate";
NSString* const GBSubmoduleStatusNotUpToDate = @"GBSubmoduleStatusNotUpToDate";

@implementation GBSubmodule

@synthesize remoteURL;
@synthesize path;
@synthesize status;
@synthesize repositoryController;

@synthesize repository;


#pragma mark Object lifecycle

- (void) dealloc
{
  self.remoteURL = nil;
  self.path      = nil;
  self.status = nil;
  self.repositoryController = nil;
  
  [super dealloc];
}



#pragma mark Interrogation



- (NSURL*) localURL
{
  return [NSURL URLWithString:[self path] relativeToURL:[self.repository url]];
}

- (NSString*) localPath
{
  return [[self localURL] path];
}

- (NSURL*) repositoryURL
{
  return [[self repository] url];
}

- (NSString*) repositoryPath
{
  return [[self repositoryURL] path];
}

- (BOOL) isCloned
{
  return ![self.status isEqualToString:GBSubmoduleStatusNotCloned];
}



#pragma mark Mutation


- (void) pullWithBlock:(void(^)())block
{
  GBTask* task = [self.repository task];
  task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", [self localPath], nil];
  [self.repository launchTask:task withBlock:block];
}





#pragma mark GBSidebarItem



- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBSubmodule:%p", self];
}

- (NSInteger) numberOfChildrenInSidebar
{
  return [[self repositoryController] numberOfChildrenInSidebar];
}

- (BOOL) isExpandableInSidebar
{
  return [[self repositoryController] isExpandableInSidebar];
}

- (id<GBObsoleteSidebarItem>) childForIndexInSidebar:(NSInteger)index
{
  return [[self repositoryController] childForIndexInSidebar:index];
}

- (id<GBObsoleteSidebarItem>) findItemWithIndentifier:(NSString*)identifier
{
  // TODO: test drag and drop and rewrite this code
  if (!identifier) return nil;
  if ([[self sidebarItemIdentifier] isEqual:identifier]) return self;
  return nil;
}

- (NSString*) nameInSidebar
{
  return [self path];
}

- (NSString*) tooltipInSidebar
{
  return [[[self localURL] absoluteURL] path];
}

- (id<GBRepositoriesControllerLocalItem>) repositoriesControllerLocalItem
{
  // TODO: should probably return its parent repositoryController, but only that which is not inside the submodule itself
  // TODO: think hard about it later!
  return nil;
}

- (BOOL) isRepository
{
  return NO;
}

- (BOOL) isRepositoriesGroup
{
  return NO;
}

- (BOOL) isSubmodule
{
  return YES;
}

- (NSCell*) sidebarCell
{
  NSCell* cell = [[[self sidebarCellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (Class) sidebarCellClass
{
  // TODO: use GBSubmoduleCell to render custom "download" button etc.
  return [GBSubmoduleCell class];
}

- (BOOL) isDraggableInSidebar
{
  return NO;
}

- (BOOL) isEditableInSidebar
{
  return NO;
}

- (BOOL) isExpandedInSidebar
{
  return [[self repositoryController] isExpandedInSidebar];
}

- (void) setExpandedInSidebar:(BOOL)expanded
{
  [[self repositoryController] setExpandedInSidebar:expanded];
}

- (NSInteger) badgeValue
{
	return [[self repositoryController] badgeValue]; // TODO: return badgeValue for the repositoryController
}

- (NSInteger) accumulatedBadgeValue
{
	return [[self repositoryController] accumulatedBadgeValue]; // TODO: return accumulatedBadgeValue for the repositoryController
}

- (BOOL) isSpinningInSidebar
{
  return [[self repositoryController] isSpinningInSidebar];
}

- (BOOL) isAccumulatedSpinningInSidebar
{
  return [[self repositoryController] isAccumulatedSpinningInSidebar];
}

- (NSProgressIndicator*) sidebarSpinner
{
  return [[self repositoryController] sidebarSpinner];
}

- (void) setSidebarSpinner:(NSProgressIndicator*)spinnerView
{
  [[self repositoryController] setSidebarSpinner:spinnerView];
}

- (void) hideAllSpinnersInSidebar
{
  [[self repositoryController] hideAllSpinnersInSidebar];
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[self localURL] writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  return [[self localURL] pasteboardPropertyListForType:type];
}

@end
