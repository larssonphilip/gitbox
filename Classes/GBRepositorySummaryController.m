#import "GBRepository.h"
#import "GBRemote.h"
#import "GBRepositorySummaryController.h"
#import "GBTaskWithProgress.h"
#import "GitRepository.h"
#import "GitConfig.h"

@interface GBRepositorySummaryController ()
- (NSString*) parentFolder;
- (NSString*) repoTitle;
- (NSString*) repoPath;
- (NSString*) repoURLString;
- (NSString*) repoURLString:(NSUInteger)anIndex;
- (void) hideRemoteAddressFieldsCount:(int)numberOfFieldsToHide;
@end

@implementation GBRepositorySummaryController

@synthesize pathLabel;
@synthesize originLabel;
@synthesize remoteLabel1;
@synthesize remoteField1;
@synthesize remoteLabel2;
@synthesize remoteField2;
@synthesize remoteLabel3;
@synthesize remoteField3;
@synthesize remainingView;
@synthesize sizeField;
@synthesize numberOfCommitsField;
@synthesize numberOfContributorsField;

- (void) dealloc
{
	self.pathLabel = nil;
	self.originLabel = nil;  
	[super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
	if ((self = [super initWithRepository:repo]))
	{
	}
	return self;
}

- (NSString*) title
{
	return NSLocalizedString(@"Summary", @"");
}

- (void) viewDidAppear
{
	[super viewDidAppear];
	
	[self.pathLabel setStringValue:self.repoPath];
	
	NSArray* remotes = self.repository.remotes;
	if (remotes.count == 0)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address:", @"");
		self.remoteField1.stringValue = @"";
		[self hideRemoteAddressFieldsCount:2];
	}
	else if (remotes.count == 1)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address:", @"");
		self.remoteField1.stringValue = [[remotes objectAtIndex:0] URLString];

		[self hideRemoteAddressFieldsCount:2];
	}
	else
	{
		
	}
	
	[self.originLabel setStringValue:self.repoURLString];
	
	[self.repository.libgitRepository.config enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSLog(@"Config: %@ => %@", key, obj);
	}];
	
	// TODO: add label and strings for:
	// - path + disclosure button like in Xcode locations preference
	// - every remote URL (if none, pre)
	
	// TODO: support multiple URLs
	// TODO: add more labels for useless stats like:
	// - number of commits, tags, 
	// - creation date, 
	// - size on disk, 
	// - committers etc.
}


- (void) save
{
	// TODO: save the remote addresses
}


#pragma mark Private


- (void) hideRemoteAddressFieldsCount:(int)numberOfFieldsToHide
{
	CGFloat remainingViewOffset = 0.0;
	if (numberOfFieldsToHide >= 1)
	{
		// hide the last one
	}
	if (numberOfFieldsToHide >= 2)
	{
		// hide the pre-last one
	}
	
	NSRect rect = self.remainingView.frame;
	rect.size.height += remainingViewOffset;
}


- (NSString*) parentFolder
{
	NSArray* pathComps = [[self.repository.url path] pathComponents];
	
	if ([pathComps count] < 2) return @"";
	
	return [pathComps objectAtIndex:[pathComps count] - 2];
}

- (NSString*) repoTitle
{
	NSString* s = [self.repository.url path];
	s = [s lastPathComponent];
	return s ? s : @"";
}

- (NSString*) repoPath
{
	NSString* s = [self.repository.url path];
	NSString* homePath = NSHomeDirectory();
	if (homePath)
	{
		NSRange r = [s rangeOfString:homePath];
		if (r.location == 0)
		{
			s = [s stringByReplacingOccurrencesOfString:homePath withString:@"~" options:0 range:r];
		}
	}
	return s ? s : @"";
}

- (NSString*) repoURLString
{
	NSString* url = [[self.repository firstRemote] URLString];
	return url ? url : @"";
}

- (IBAction) optimizeRepository:(NSButton*)button
{
	// TODO: launch "git gc", monitor status
	
	NSString* originalTitle = button.title;
	[button setEnabled:NO];
	button.title = NSLocalizedString(@"Optimizing...", @"");
	
	GBTaskWithProgress* gitgcTask = [GBTaskWithProgress taskWithRepository:self.repository];
	gitgcTask.arguments = [NSArray arrayWithObject:@"gc"];
	gitgcTask.progressUpdateBlock = ^{
		button.title = [NSString stringWithFormat:@"%@ %d%", NSLocalizedString(@"Optimizing...", @""), (int)roundf(gitgcTask.progress*100.0)];
	};
	[gitgcTask launchWithBlock:^{
		[button setEnabled:YES];
		button.title = originalTitle;
	}];
}

- (IBAction)openInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:self.repository.url];
}

@end
