#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBSidebarItem.h"
#import "GBSubmoduleCloningViewController.h"
#import "GBSubmoduleCloningController.h"
#import "GBTaskWithProgress.h"
#import "GBSidebarCell.h"
#import "GBRepositoryController.h"
#import "GBAskPassController.h"
#import "NSString+OAStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"


@interface GBSubmoduleCloningController ()
@property(nonatomic,retain) GBTaskWithProgress* task;
@property(nonatomic, assign, readwrite) NSInteger isDisabled;
@property(nonatomic, assign, readwrite) NSInteger isSpinning;
@end

@implementation GBSubmoduleCloningController

@synthesize submodule=_submodule;
@synthesize window;
@synthesize viewController;

@synthesize task;
@synthesize error;

@synthesize isDisabled;
@synthesize isSpinning;
@synthesize sidebarItemProgress;
@synthesize progressStatus;


- (void) dealloc
{
	self.window      = nil;
	self.viewController.repositoryController = nil;
	self.viewController = nil;
	[self.task terminate];
	self.task        = nil;
	self.error       = nil;
	self.progressStatus = nil;
	[super dealloc];
}

- (id) initWithSubmodule:(GBSubmodule*)submodule
{
	if ((self = [super init]))
	{
		self.submodule = submodule;
		self.viewController = [[[GBSubmoduleCloningViewController alloc] initWithNibName:@"GBSubmoduleCloningViewController" bundle:nil] autorelease];
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

- (void) startDownload
{
	[GBAskPassController launchedControllerWithAddress:self.remoteURL.absoluteString taskFactory:^{
		
		self.progressStatus = nil;
		self.sidebarItemProgress = 0.0;
		[self.sidebarItem update];
		[self notifyWithSelector:@selector(submoduleCloningControllerProgress:)];
		
		GBTaskWithProgress* t = [[GBTaskWithProgress new] autorelease];

		t.repository = self.submodule.repository;
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
		
		t.didTerminateBlock = ^{
			
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
			[self.sidebarItem update];
			
			self.task = nil;
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
			}
			
			[self.sidebarItem removeAllViews];
			
			if ([t isError])
			{
				NSLog(@"GBSubmoduleCloningController: did FAIL to clone at %@", self.submodule.path);
				NSLog(@"GBSubmoduleCloningController: output: %@", [t UTF8ErrorAndOutput]);
				[self notifyWithSelector:@selector(submoduleCloningControllerDidFail:)];
			}
			else
			{
				NSLog(@"GBSubmoduleCloningController: did finish clone at %@", self.submodule.path);
				[self notifyWithSelector:@selector(submoduleCloningControllerDidFinish:)];
			}
		};
		return (id)task;
	}];
}

- (void) cancelDownload
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
	[self notifyWithSelector:@selector(submoduleCloningControllerDidCancel:)];
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


- (GBSidebarItem*) sidebarItem
{
	return self.submodule.sidebarItem;
}

- (NSString*) sidebarItemTitle
{
	return [self.submodule.localURL.path lastPathComponent];
}

- (NSString*) sidebarItemTooltip
{
	return self.submodule.localURL.absoluteURL.path;
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

- (BOOL) sidebarItemIsSpinning
{
	return self.isSpinning;
}




#pragma mark NSPasteboardWriting




- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return [[NSArray arrayWithObjects:NSPasteboardTypeString, (NSString*)kUTTypeFileURL, nil] 
			arrayByAddingObjectsFromArray:[self.submodule.localURL writableTypesForPasteboard:pasteboard]];
}

- (id)pasteboardPropertyListForType:(NSString *)type
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
