#import "GBSidebarItem.h"
#import "GBRepositoryCloningViewController.h"
#import "GBRepositoryCloningController.h"
#import "GBCloneTask.h"
#import "GBSidebarCell.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBRepositoryCloningController ()
@property(nonatomic,retain) GBCloneTask* task;
@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;

@end

@implementation GBRepositoryCloningController

@synthesize sidebarItem;
@synthesize window;
@synthesize viewController;

@synthesize sourceURL;
@synthesize targetURL;
@synthesize task;
@synthesize error;

@synthesize isDisabled;
@synthesize isSpinning;


- (void) dealloc
{
  self.sidebarItem = nil;
  self.window      = nil;
  self.viewController = nil;
  self.sourceURL   = nil;
  self.targetURL   = nil;
  [self.task terminate];
  self.task        = nil;
  self.error       = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
    self.sidebarItem.object = self;
    self.sidebarItem.selectable = YES;
    self.sidebarItem.draggable = YES;
    self.sidebarItem.image = [NSImage imageNamed:NSImageNameFolder];
    self.sidebarItem.cell = [[[GBSidebarCell alloc] initWithItem:self.sidebarItem] autorelease];
    
    self.viewController = [[[GBRepositoryCloningViewController alloc] initWithNibName:@"GBRepositoryCloningViewController" bundle:nil] autorelease];
    self.viewController.repositoryController = self;
  }
  return self;
}

- (NSURL*) url
{
  return self.targetURL;
}

- (void) startCloning
{
  GBCloneTask* t = [[GBCloneTask new] autorelease];
  self.isDisabled++;
  self.isSpinning++;
  t.sourceURL = self.sourceURL;
  t.targetURL = self.targetURL;
  self.task = t;
  [t launchWithBlock:^{
    self.isSpinning--;
    self.task = nil;
    if ([t isError])
    {
      self.error = [NSError errorWithDomain:@"Gitbox"
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [t UTF8OutputStripped], NSLocalizedDescriptionKey,
                                             [NSNumber numberWithInt:[t terminationStatus]], @"terminationStatus",
                                             [t command], @"command",
                                             nil
                                            ]];
    }
    
    if (t.isTerminated || [t isError])
    {
      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
      NSLog(@"GBCloningRepositoryController: output: %@", [t UTF8OutputStripped]);
      [self notifyWithSelector:@selector(cloningRepositoryControllerDidFail:)];
    }
    else
    {
      NSLog(@"GBCloningRepositoryController: did finish clone at %@", self.targetURL);
      [self notifyWithSelector:@selector(cloningRepositoryControllerDidFinish:)];
    }
  }];
}

- (void) cancelCloning
{
  if (self.task)
  {
    self.isSpinning--;
    [self.task terminate];
    self.task = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.targetURL error:NULL];
  }
  [self notifyWithSelector:@selector(cloningRepositoryControllerDidCancel:)];
}








#pragma mark GBMainWindowItem



- (NSString*) windowTitle
{
  return [[[self url] path] twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
  return self.targetURL;
}

- (void) didSelectWindowItem
{
}





#pragma mark GBSidebarItemObject


- (NSString*) sidebarItemTitle
{
  return [[[self url] path] lastPathComponent];
}

- (NSString*) sidebarItemTooltip
{
  return [[[self url] absoluteURL] path];
}

- (id) sidebarItemContentsPropertyList
{
  return nil;
}

- (void) sidebarItemLoadContentsFromPropertyList:(id)plist
{
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
