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

@synthesize repository;

@synthesize remoteURL;
@synthesize path;
@synthesize status;
@synthesize sidebarItem;
@synthesize repositoryController;


#pragma mark Object lifecycle

- (void) dealloc
{
	//NSLog(@"GBSubmodule#dealloc");
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

- (IBAction) download:(id)sender
{
	if ([self.repositoryController respondsToSelector:@selector(startDownload)])
	{
		[self.repositoryController performSelector:@selector(startDownload)];
	}
}


#pragma mark Mutation


- (void) updateHeadWithBlock:(void(^)())block
{
	GBTask* task = [self.repository task];
	task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", [self localPath], nil];
	[self.repository launchTask:task withBlock:block];
}





#pragma mark GBSidebarItem


- (NSInteger) sidebarItemNumberOfChildren
{
	if ([self.repositoryController respondsToSelector:@selector(sidebarItemNumberOfChildren)])
	{
		return [self.repositoryController sidebarItemNumberOfChildren];
	}
	return 0;
}

- (GBSidebarItem*) sidebarItemChildAtIndex:(NSInteger)anIndex
{
	if ([self.repositoryController respondsToSelector:@selector(sidebarItemChildAtIndex:)])
	{
		return [self.repositoryController sidebarItemChildAtIndex:anIndex];
	}
	return nil;
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
	if ([self.repositoryController respondsToSelector:@selector(sidebarItemBadgeInteger)])
	{
		return [self.repositoryController sidebarItemBadgeInteger];
	}
	return 0;
}

- (BOOL) sidebarItemIsSpinning
{
	if ([self.repositoryController respondsToSelector:@selector(sidebarItemIsSpinning)])
	{
		return [self.repositoryController sidebarItemIsSpinning];
	}
	return NO;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return [[self localURL] writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	return [[self localURL] pasteboardPropertyListForType:type];
}



#pragma mark GBMainWindowItem


- (NSString*) windowTitle
{
	if ([self.repositoryController respondsToSelector:@selector(windowTitle)])
	{
		return [self.repositoryController windowTitle];
	}
	return nil;
}

- (NSURL*) windowRepresentedURL
{
	if ([self.repositoryController respondsToSelector:@selector(windowRepresentedURL)])
	{
		return [self.repositoryController windowRepresentedURL];
	}
	return nil;
}

- (id) toolbarController
{
	if ([self.repositoryController respondsToSelector:@selector(toolbarController)])
	{
		return [self.repositoryController toolbarController];
	}
	return nil;
}

- (id) viewController
{
	if ([self.repositoryController respondsToSelector:@selector(viewController)])
	{
		return [self.repositoryController viewController];
	}
	return nil;
}

- (void) willDeselectWindowItem
{
	if ([self.repositoryController respondsToSelector:@selector(willDeselectWindowItem)])
	{
		[self.repositoryController willDeselectWindowItem];
	}
}

- (void) didSelectWindowItem
{
	if ([self.repositoryController respondsToSelector:@selector(didSelectWindowItem)])
	{
		[self.repositoryController didSelectWindowItem];
	}
}

- (void) windowDidBecomeKey
{
	if ([self.repositoryController respondsToSelector:@selector(windowDidBecomeKey)])
	{
		[self.repositoryController windowDidBecomeKey];
	}
}

- (NSUndoManager*) undoManager
{
	if ([self.repositoryController respondsToSelector:@selector(undoManager)])
	{
		return [self.repositoryController undoManager];
	}
	return nil;
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
