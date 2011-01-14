#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"


@implementation GBSubmodule

@synthesize remoteURL;
@synthesize path;
@synthesize repository;


#pragma mark Object lifecycle

- (void) dealloc
{
  self.remoteURL = nil;
  self.path      = nil;

  [super dealloc];
}



#pragma mark Interrogation

- (NSURL*) localURL
{
  return [NSURL URLWithString:[self path] relativeToURL:[[self repository] url]];
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



#pragma mark Mutation

- (void) pullWithBlock:(void(^)())block
{
  OATask* task = [OATask task];

  task.currentDirectoryPath = [self repositoryPath];

  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  
  
  task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", [self localPath], nil];
  
  [task launchWithBlock:block];
}



#pragma mark GBSidebarItem

- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBSubmodule:%p", self];
}

- (NSInteger) numberOfChildrenInSidebar
{
  return 0;
}

- (BOOL) isExpandableInSidebar
{
  return NO;
}

- (id<GBSidebarItem>) childForIndexInSidebar:(NSInteger)index
{
  return nil;
}

- (id<GBSidebarItem>) findItemWithIndentifier:(NSString*)identifier
{
  if (!identifier) return nil;
  if ([[self sidebarItemIdentifier] isEqual:identifier]) return self;
  return nil;
}

- (NSString*) nameInSidebar
{
  return [[[self localURL] path] lastPathComponent];
}

- (NSString*) tooltipInSidebar
{
  return [[self localURL] path];
}

- (GBBaseRepositoryController*) repositoryController
{
  // TODO: return self.repositoryController
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
  // TODO; return [GBSubmoduleCell class];
  return nil;
}

- (BOOL) isDraggableInSidebar
{
  return YES;
}

- (BOOL) isEditableInSidebar
{
  return NO;
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
