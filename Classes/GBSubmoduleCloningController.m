#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBSidebarItem.h"
#import "GBSubmoduleCell.h"
#import "GBSubmoduleCloningViewController.h"
#import "GBSubmoduleCloningController.h"
#import "GBAuthenticatedTask.h"
#import "GBRepositoryController.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBSubmoduleCloningController ()
@property(nonatomic,strong) GBAuthenticatedTask* task;
@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;
@property(nonatomic, strong, readwrite) GBSidebarItem* sidebarItem;
@end

@implementation GBSubmoduleCloningController

@synthesize submodule=_submodule;
@synthesize parentRepositoryController=_parentRepositoryController;
@synthesize viewController;

@synthesize task;
@synthesize error;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize sidebarItemProgress;
@synthesize progressStatus;
@synthesize sidebarItem;

- (void) dealloc
{
	self.viewController.repositoryController = nil;
	[self.task terminate];
	
	
	if (self.sidebarItem.object == self) self.sidebarItem.object = nil;
}

- (id) initWithSubmodule:(GBSubmodule*)submodule
{
	if ((self = [super init]))
	{
		self.submodule = submodule;
		
		self.sidebarItem = [[GBSidebarItem alloc] init];
		self.sidebarItem.object = self;
		self.sidebarItem.draggable = NO;
		self.sidebarItem.selectable = YES;
		self.sidebarItem.editable = NO;
		self.sidebarItem.cell = [[GBSubmoduleCell alloc] initWithItem:self.sidebarItem];
		
		self.viewController = [[GBSubmoduleCloningViewController alloc] initWithNibName:@"GBSubmoduleCloningViewController" bundle:nil];
		self.viewController.repositoryController = self;
	}
	return self;
}

- (BOOL) isStarted
{
	return !!self.task;
}

- (NSURL*) remoteURL
{
	return self.submodule.remoteURL;
}

- (IBAction)startDownload:(id)sender
{
	self.progressStatus = nil;
	self.sidebarItemProgress = 0.0;
	[self.sidebarItem update];
	[self notifyWithSelector:@selector(submoduleCloningControllerProgress:)];
	
	GBAuthenticatedTask* t = [GBAuthenticatedTask new];
	
	t.remoteAddress = self.remoteURL.absoluteString;
	t.ignoreMissingRepository = YES;
	t.dispatchQueue = self.submodule.dispatchQueue;
	t.currentDirectoryPath = self.submodule.parentURL.path;
	t.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--progress", @"--", self.submodule.path, nil];
	
	if ([GBTask isSnowLeopard])
	{
		t.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--", self.submodule.path, nil];
	}
	
	self.isDisabled++;
	self.isSpinning++;
	[self.sidebarItem update];
	
	self.task = t;
	
	[self notifyWithSelector:@selector(submoduleCloningControllerDidStart:)];
	
	t.progressUpdateBlock = ^(){
		if (!self.task) return;
		self.sidebarItemProgress = t.progress;
		self.progressStatus = t.status;
		[self.sidebarItem update];
		[self notifyWithSelector:@selector(submoduleCloningControllerProgress:)];
	};
	
	[t launchWithBlock:^{
		
		if (!self.task) // was terminated
		{
			//NSLog(@"!! No task, returning and cleaning up the folder");
			if (self.submodule.localURL) [[NSFileManager defaultManager] removeItemAtURL:self.submodule.localURL error:NULL];
			return;
		}
		
		self.sidebarItemProgress = 0.0;
		self.progressStatus = @"";
		
		//NSLog(@"!! Task finished. Decrementing a spinner.");
		self.isSpinning--;

		self.task = nil;
		
		if (t.authenticationFailed && !t.authenticationCancelledByUser)
		{
			[self startDownload:sender];
			[self notifyWithSelector:@selector(submoduleCloningControllerDidRestart:)];
			return;
		}
		
		if ([t isError])
		{
			self.error = [NSError errorWithDomain:@"Gitbox"
											 code:1 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   [t UTF8ErrorAndOutput], NSLocalizedDescriptionKey,
												   [NSNumber numberWithInt:[t terminationStatus]], @"terminationStatus",
												   [t command], @"command",
												   nil
												   ]];
			NSLog(@"GBSubmoduleCloningController: did FAIL to clone at %@", self.submodule.path);
			NSLog(@"GBSubmoduleCloningController: output: %@", [t UTF8ErrorAndOutput]);
			[self notifyWithSelector:@selector(submoduleCloningControllerDidFail:)];
		}
		else
		{
			self.submodule.status = GBSubmoduleStatusJustCloned;
			
			NSLog(@"GBSubmoduleCloningController: did finish clone at %@", self.submodule.path);
			[self notifyWithSelector:@selector(submoduleCloningControllerDidFinish:)];
		}
		
		[self.sidebarItem removeAllViews];
		[self.sidebarItem update];
	}];
}

- (IBAction)cancelDownload:(id)sender
{
	if (self.task)
	{
		//NSLog(@"!! Task cancelled. Decrementing a spinner. Terminating a task.");
		self.isSpinning--;
		OATask* t = self.task;
		self.task = nil;
		[t terminate];
		self.progressStatus = @"";
		self.sidebarItemProgress = 0.0;
		[self.sidebarItem removeAllViews];
		[self.sidebarItem update];
	}
	[self notifyWithSelector:@selector(submoduleCloningControllerDidCancel:)];
}

- (void) start
{
	// noop for compat with GBRepositoryController
}

- (void) stop
{
	OATask* t = self.task;
	self.task = nil;
	[t terminate];
	[self.sidebarItem removeAllViews];
	[self.sidebarItem update];
}





#pragma mark GBMainWindowItem



- (NSString*) windowTitle
{
	return [self.submodule.localURL.path twoLastPathComponentsWithDash];
}

- (NSURL*) windowRepresentedURL
{
	return self.submodule.localURL;
}

- (void) didSelectWindowItem
{
}





#pragma mark GBSidebarItemObject


- (NSString*) sidebarItemTitle
{
	return [self.submodule.path lastPathComponent];
}

- (NSString*) sidebarItemTooltip
{
	return self.submodule.localURL.absoluteURL.path;
}

- (BOOL) sidebarItemIsSpinning
{
	return self.isSpinning;
}

- (BOOL) sidebarItemIsExpandable
{
	return NO;
}

- (NSInteger) sidebarItemNumberOfChildren
{
	return 0;
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
	return nil;
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
			arrayByAddingObjectsFromArray:[self.submodule.localURL writableTypesForPasteboard:pasteboard]];
}

- (id) pasteboardPropertyListForType:(NSString *)type
{
	if ([type isEqualToString:(NSString*)kUTTypeFileURL])
	{
		return self.submodule.localURL.absoluteURL;
	}
	if ([type isEqualToString:NSPasteboardTypeString])
	{
		return self.submodule.localURL.path;
	}
	return [self.submodule.localURL pasteboardPropertyListForType:type];
}





@end
