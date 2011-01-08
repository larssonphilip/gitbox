#import "GBBaseRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "GBRepositoryCell.h"

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


- (NSCell*) cell
{
  NSCell* cell = [[[self cellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (Class) cellClass
{
  return [GBRepositoryCell class];
}





#pragma mark GBSourcesControllerItem


- (NSInteger) numberOfChildrenInSidebar
{
  return 0;
}

- (BOOL) isExpandableInSidebar
{
  return NO;
}

- (id<GBSourcesControllerItem>) childForIndexInSidebar:(NSInteger)index
{
  return nil;
}

- (NSString*) nameInSidebar
{
  return [[[self url] path] lastPathComponent];
}


@end
