#import "GBBaseRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "GBRepositoryCell.h"
#import "OABlockQueue.h"

@implementation GBBaseRepositoryController

@synthesize updatesQueue;
@synthesize sidebarSpinner;

@synthesize displaysTwoPathComponents;
@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.updatesQueue = nil;
  self.sidebarSpinner = nil;
  [super dealloc];
}

- (NSURL*) url
{
  // overriden in subclasses
  return nil;
}


// <obsolete>
- (NSString*) nameForSourceList
{
  if (self.displaysTwoPathComponents)
  {
    return [self longNameForSourceList];
  }
  else
  {
    return [self shortNameForSourceList];
  }
}

- (NSString*) shortNameForSourceList
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) longNameForSourceList
{
  return [[[self url] path] twoLastPathComponentsWithSlash];
}

- (NSString*) titleForSourceList
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) subtitleForSourceList
{
  return [self parentFolderName];
}

- (NSString*) parentFolderName
{
  return [[[[self url] path] stringByDeletingLastPathComponent] lastPathComponent];
}
// </obsolete>



- (NSString*) badgeLabel
{
  return nil;
}

- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return nil;
}

- (void) updateWithBlock:(void(^)())block { if (block) block(); }

- (void) updateQueued
{
	[self.updatesQueue addBlock:^{
		[self updateWithBlock:^{
			[self.updatesQueue endBlock];
		}];
	}];
}


- (void) beginBackgroundUpdate {}
- (void) endBackgroundUpdate {}

- (void) start {}
- (void) stop
{
  [self.sidebarSpinner removeFromSuperview];
}

- (void) didSelect
{
}



#pragma mark GBRepositoriesControllerLocalItem


- (void) enumerateRepositoriesWithBlock:(void(^)(GBBaseRepositoryController* repoCtrl))aBlock
{
  // TODO: enumerate also all submodules' controllers.
  if (aBlock) aBlock(self);
}

- (GBBaseRepositoryController*) findRepositoryControllerWithURL:(NSURL*)aURL
{
  if ([[self url] isEqual:aURL]) return self;
  // TODO: add check for submodules here
  return nil;
}

- (NSUInteger) repositoriesCount
{
  return 1;
}

- (BOOL) hasRepositoryController:(GBBaseRepositoryController*)repoCtrl
{
  return (self == repoCtrl);
}

- (void) removeLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
{
  // no op
}

- (id) plistRepresentationForUserDefaults
{
  NSData* data = [[self url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                          includingResourceValuesForKeys:nil
                                           relativeToURL:nil
                                                   error:NULL];
  if (!data) return nil;
  return [NSDictionary dictionaryWithObjectsAndKeys:
          data, @"URL", 
          nil];
}

- (GBRepositoriesGroup*) groupContainingLocalItem:(id<GBRepositoriesControllerLocalItem>)aLocalItem
{
  return nil;
}


#pragma mark GBSidebarItem


- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBBaseRepositoryController:%p", self];
}

- (NSString*) nameInSidebar
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) tooltipInSidebar
{
  return [[self url] path];
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

- (GBBaseRepositoryController*) repositoryController
{
  return self;
}

- (id<GBRepositoriesControllerLocalItem>) repositoriesControllerLocalItem
{
  return self;
}

- (BOOL) isRepository
{
  return YES;
}

- (BOOL) isRepositoriesGroup
{
  return NO;
}

- (BOOL) isSubmodule
{
  return NO;
}

- (NSCell*) sidebarCell
{
  NSCell* cell = [[[self sidebarCellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (Class) sidebarCellClass
{
  return [GBRepositoryCell class];
}

- (BOOL) isDraggableInSidebar
{
  return YES;
}

- (BOOL) isEditableInSidebar
{
  return NO;
}

- (BOOL) isExpandedInSidebar
{
  // TODO: return expanded state for submodules list
  return YES;
}

- (void) setExpandedInSidebar:(BOOL)expanded
{
  // TODO: save expanded state for submodules list
}



#pragma mark NSPasteboardWriting


- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[NSArray arrayWithObjects:GBSidebarItemPasteboardType, NSPasteboardTypeString, (NSString*)kUTTypeFileURL, nil] 
          arrayByAddingObjectsFromArray:[[self url] writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqual:GBSidebarItemPasteboardType])
  {
    return [self sidebarItemIdentifier];
  }
  if ([type isEqualToString:(NSString*)kUTTypeFileURL])
  {
    return [[self url] absoluteURL];
  }
  if ([type isEqualToString:NSPasteboardTypeString])
  {
    return [[self url] path];
  }
  return [[self url] pasteboardPropertyListForType:type];
}



@end
