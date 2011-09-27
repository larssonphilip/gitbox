#import "GBRepository.h"
#import "GBRemote.h"
#import "GBRepositorySummaryController.h"
#import "GBTaskWithProgress.h"
#import "GitRepository.h"
#import "GitConfig.h"

@interface GBRepositorySummaryController ()
@property(nonatomic, retain) NSArray* remotes;
@property(nonatomic, retain) NSArray* labels;
@property(nonatomic, retain) NSArray* fields;

- (NSString*) parentFolder;
- (NSString*) repoTitle;
- (NSString*) repoPath;
- (void) hideRemoteAddressFieldsCount:(int)numberOfFieldsToHide;
@end

@implementation GBRepositorySummaryController

@synthesize remotes;
@synthesize labels;
@synthesize fields;

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
	self.remotes = nil;
	self.labels = nil;
	self.fields = nil;
	
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
	
	self.labels = [NSArray arrayWithObjects:self.remoteLabel1, self.remoteLabel2, self.remoteLabel3, nil];
	self.fields = [NSArray arrayWithObjects:self.remoteField1, self.remoteField2, self.remoteField3, nil];

	// initialize tags so they are invalid
	for (NSTextField* field in fields)
	{
		field.tag = -1;
	}
	
	self.remotes = self.repository.remotes;
	
	NSUInteger linesCount = MIN(remotes.count, self.fields.count);
	
	if (linesCount == 0)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address:", @"");
		self.remoteField1.stringValue = @"";
		self.remoteField1.tag = 0;
		linesCount = 1;
	}
	else if (linesCount == 1)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address:", @"");
		NSString* str = [[remotes objectAtIndex:0] URLString];
		self.remoteField1.stringValue = str ? str : @"";
		self.remoteField1.tag = 0;
	}
	else
	{
		for (NSUInteger i = 0; i < linesCount; i++)
		{
			NSTextField* field = [self.fields objectAtIndex:i];
			NSTextField* label = [self.labels objectAtIndex:i];
			GBRemote* remote   = [self.remotes objectAtIndex:i];
			
			label.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Remote address (%@):", @""), remote.alias];
			NSString* str = [remote URLString];
			field.stringValue = str ? str : @"";
			field.tag = i;
		}
	}
	
	CGFloat remainingViewOffset = 0.0;
	
	for (NSUInteger i = linesCount; i < fields.count; i++)
	{
		NSTextField* f = [self.labels objectAtIndex:i];
		[f setHidden:YES];
		f = [self.fields objectAtIndex:i];
		[f setHidden:YES];
		remainingViewOffset += 38 + 17;
	}
	
	NSRect rect = self.remainingView.frame;
	rect.size.height += remainingViewOffset;
	
	
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
	// self.remotes
	
	
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
	NSString* originalTitle = button.title;
	[button setEnabled:NO];
	NSString* aTitle = NSLocalizedString(@"Optimizing...", @"");
	button.title = aTitle;
	
	GBTaskWithProgress* gitgcTask = [GBTaskWithProgress taskWithRepository:self.repository];
	gitgcTask.arguments = [NSArray arrayWithObject:@"gc"];
	gitgcTask.progressUpdateBlock = ^{
		button.title = [NSString stringWithFormat:@"%@ %d%", aTitle, (int)roundf(gitgcTask.progress*100.0)];
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
