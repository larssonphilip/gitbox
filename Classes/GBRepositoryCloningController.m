#import "GBSidebarItem.h"
#import "GBRepositoriesController.h"
#import "GBRepositoryCloningViewController.h"
#import "GBRepositoryCloningController.h"
#import "GBCloneTask.h"
#import "GBSidebarCell.h"
#import "GBRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBRepositoryCloningController ()
@property(nonatomic,retain) GBCloneTask* task;
@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;
@end

@implementation GBRepositoryCloningController

@synthesize repositoriesController;
@synthesize sidebarItem;
@synthesize window;
@synthesize viewController;

@synthesize sourceURL;
@synthesize targetURL;
@synthesize task;
@synthesize error;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize sidebarItemProgress;
@synthesize progressStatus;


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
  self.progressStatus = nil;
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
  [self.sidebarItem update];
  t.sourceURL = self.sourceURL;
  t.targetURL = self.targetURL;
  self.task = t;
  
  [self notifyWithSelector:@selector(cloningRepositoryControllerDidStart:)];
  
  t.progressUpdateBlock = ^(){
    if (!self.task) return;
    self.sidebarItemProgress = t.progress;
    self.progressStatus = t.status;
    [self.sidebarItem update];
    [self notifyWithSelector:@selector(cloningRepositoryControllerProgress:)];
  };
  
  [t launchWithBlock:^{
    
    if (!self.task) // was terminated
    {
      //NSLog(@"!! No task, returning and cleaning up the folder");
      if (self.targetURL) [[NSFileManager defaultManager] removeItemAtURL:self.targetURL error:NULL];
      return;
    }
    
    self.sidebarItemProgress = 0.0;
    self.progressStatus = @"";
    
    //NSLog(@"!! Task finished. Decrementing a spinner.");
    self.isSpinning--;
    [self.sidebarItem update];
    
    self.task = nil;
    if ([t isError])
    {
      self.error = [NSError errorWithDomain:@"Gitbox"
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [t UTF8Error], NSLocalizedDescriptionKey,
                                             [NSNumber numberWithInt:[t terminationStatus]], @"terminationStatus",
                                             [t command], @"command",
                                             nil
                                            ]];
    }
    
    [self.sidebarItem removeAllViews];
    
    if ([t isError])
    {
      NSLog(@"GBCloningRepositoryController: did FAIL to clone at %@", self.targetURL);
      NSLog(@"GBCloningRepositoryController: output: %@", [t UTF8Error]);
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
    //NSLog(@"!! Task cancelled. Decrementing a spinner. Terminating a task.");
    self.isSpinning--;
    [self.sidebarItem update];
    OATask* t = self.task;
    self.task = nil;
    [t terminate];
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

- (BOOL) sidebarItemIsSpinning
{
  return self.isSpinning;
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
