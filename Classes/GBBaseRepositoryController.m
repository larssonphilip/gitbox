#import "GBBaseRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "OABlockQueue.h"

@implementation GBBaseRepositoryController

@synthesize updatesQueue;
@synthesize autofetchQueue;
@synthesize sidebarSpinner;

@synthesize displaysTwoPathComponents;
@synthesize isDisabled;
@synthesize isSpinning;
@synthesize delegate;

- (void) dealloc
{
  self.updatesQueue = nil;
  self.autofetchQueue = nil;
  NSLog(@"GBBaseRepositoryController dealloc %@", self);
  [self.sidebarSpinner removeFromSuperview];
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



- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return nil;
}

- (NSImage*) icon
{
  NSString* path = [[self url] path];
  if (!path) return nil;
  
  while ([path length] > 0 && ![[NSFileManager defaultManager] fileExistsAtPath:path])
  {
    path = [path stringByDeletingLastPathComponent];
  }
  return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

- (void) initialUpdateWithBlock:(void(^)())block { if (block) block(); }

- (void) start {}
- (void) stop
{
  [self.sidebarSpinner removeFromSuperview];
}

- (void) didSelect
{
}

- (void) cleanupSpinnerIfNeeded
{
  if (![self isSpinning])
  {
    [self.sidebarSpinner removeFromSuperview];
  }
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





#pragma mark NSPasteboardWriting


- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return [[NSArray arrayWithObjects:NSPasteboardTypeString, (NSString*)kUTTypeFileURL, nil] 
          arrayByAddingObjectsFromArray:[[self url] writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
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
