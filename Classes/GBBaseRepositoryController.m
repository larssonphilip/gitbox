#import "GBBaseRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "GBRepositoryCell.h"

@implementation GBBaseRepositoryController

@synthesize displaysTwoPathComponents;
@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (NSURL*) url
{
  // overriden in subclasses
  return nil;
}

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

- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return nil;
}


- (void) setNeedsUpdateEverything {}
- (void) updateRepositoryIfNeeded {}

- (void) beginBackgroundUpdate {}
- (void) endBackgroundUpdate {}

- (void) start {}
- (void) stop {}

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

@end
