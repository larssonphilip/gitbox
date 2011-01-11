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

- (void) removeRepository:(GBBaseRepositoryController*)repoCtrl
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



#pragma mark GBSidebarItem


- (NSString*) sidebarItemIdentifier
{
  return [NSString stringWithFormat:@"GBBaseRepositoryController:%p", self];
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

- (NSString*) nameInSidebar
{
  return [[[self url] path] lastPathComponent];
}

- (GBBaseRepositoryController*) repositoryController
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


#pragma mark NSPasteboardWriting


- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[NSArray arrayWithObject:GBSidebarItemPasteboardType] 
          arrayByAddingObjectsFromArray:[[self url] writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if ([type isEqual:GBSidebarItemPasteboardType])
  {
    return [self sidebarItemIdentifier];
  }
  return [[self url] pasteboardPropertyListForType:type];
}



@end
