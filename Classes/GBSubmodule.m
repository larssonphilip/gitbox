#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"

#import "GBSidebarItem.h"
#import "GBSubmoduleCell.h"
#import "GBRepositoryController.h"

NSString* const GBSubmoduleStatusNotCloned = @"GBSubmoduleStatusNotCloned";
NSString* const GBSubmoduleStatusUpToDate = @"GBSubmoduleStatusUpToDate";
NSString* const GBSubmoduleStatusNotUpToDate = @"GBSubmoduleStatusNotUpToDate";

@implementation GBSubmodule

@synthesize remoteURL;
@synthesize path;
@synthesize status;
@synthesize sidebarItem;
@synthesize repositoryController;

@synthesize repository;


#pragma mark Object lifecycle

- (void) dealloc
{
  NSLog(@"GBSubmodule#dealloc");
  self.remoteURL = nil;
  self.path      = nil;
  self.status = nil;
  self.sidebarItem.object = nil;
  self.sidebarItem = nil;
  self.repositoryController = nil;
  
  [super dealloc];
}

- (id)init
{
  if ((self = [super init]))
  {
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.draggable = YES;
    self.sidebarItem.selectable = YES;
    self.sidebarItem.cell = [[[GBSubmoduleCell alloc] initWithItem:self.sidebarItem] autorelease];
  }
  return self;
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


- (NSInteger) sidebarItemNumberOfChildren
{
  return [self.repositoryController sidebarItemNumberOfChildren];
}

 - (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
  return [self.repositoryController sidebarItemChildAtIndex:anIndex];
}

- (NSString*) sidebarItemTitle
{
  return [self path];
}

- (NSString*) sidebarItemTooltip
{
  return [[[self localURL] absoluteURL] path];
}

 - (BOOL) sidebarItemIsExpandable
{
  return [self.repositoryController sidebarItemIsExpandable];
}

- (NSUInteger) sidebarItemBadgeInteger
{
	return [self.repositoryController sidebarItemBadgeInteger];
}

- (BOOL) sidebarItemIsSpinning
{
  return [self.repositoryController sidebarItemIsSpinning];
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[self localURL] writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  return [[self localURL] pasteboardPropertyListForType:type];
}





#pragma mark Persistance



- (id) sidebarItemContentsPropertyList
{
  return nil;
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
}


@end
