#import "GBTask.h"
#import "GBRepository.h"
#import "GBRemote.h"
#import "GBRepositorySummaryController.h"
#import "GBTaskWithProgress.h"
#import "GitRepository.h"
#import "GitConfig.h"
#import "GBGitConfig.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@interface GBRepositorySummaryController ()
@property(nonatomic, retain) NSArray* remotes;
@property(nonatomic, retain) NSArray* labels;
@property(nonatomic, retain) NSArray* fields;

- (NSString*) parentFolder;
- (NSString*) repoTitle;
- (NSString*) repoPath;
- (void) iterateRemoteLines:(void(^)(NSUInteger i, GBRemote* aRemote, NSTextField* field, NSTextField* label))aBlock;
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
@synthesize gitignoreTextView;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self.pathLabel setStringValue:self.repoPath];
	
	self.labels = [NSArray arrayWithObjects:self.remoteLabel1, self.remoteLabel2, self.remoteLabel3, nil];
	self.fields = [NSArray arrayWithObjects:self.remoteField1, self.remoteField2, self.remoteField3, nil];

	// initialize tags so they are invalid
	for (NSTextField* field in fields)
	{
		field.tag = -1;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateText:) name:NSControlTextDidChangeNotification object:field];
	}
	
	if (self.gitignoreTextView)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didUpdateText:)
													 name:NSTextDidChangeNotification
												   object:self.gitignoreTextView];
	}
	
	self.remotes = self.repository.remotes;
	
	NSUInteger linesCount = MIN(remotes.count, self.fields.count);
	
	if (linesCount == 0)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address", @"");
		self.remoteField1.stringValue = @"";
		self.remoteField1.tag = 0;
		linesCount = 1;
	}
	else if (linesCount == 1)
	{
		self.remoteLabel1.stringValue = NSLocalizedString(@"Remote address", @"");
		NSString* str = [[remotes objectAtIndex:0] URLString];
		self.remoteField1.stringValue = str ? str : @"";
		self.remoteField1.tag = 0;
	}
	else
	{
		[self iterateRemoteLines:^(NSUInteger i, GBRemote *remote, NSTextField *field, NSTextField *label) {
			label.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Remote address (%@)", @""), remote.alias];
			NSString* str = [remote URLString];
			field.stringValue = str ? str : @"";
			field.tag = i;
		}];
	}
	
	CGFloat remainingViewOffset = 0.0;
	
	for (NSUInteger i = linesCount; i < fields.count; i++)
	{
		NSTextField* f = [self.labels objectAtIndex:i];
		[f setHidden:YES];
		f = [self.fields objectAtIndex:i];
		[f setHidden:YES];
		remainingViewOffset += 40+22;
	}
	
	NSRect rect = self.remainingView.frame;
	rect.size.height += remainingViewOffset;
	self.remainingView.frame = rect;
	
	NSError* error = nil;
	NSString* gitignoreContents = [NSString stringWithContentsOfFile:[self.repository.path stringByAppendingPathComponent:@".gitignore"] encoding:NSUTF8StringEncoding error:&error];
	
	if (!gitignoreContents)
	{
		gitignoreContents = @"";
		//NSLog(@"GBRepositorySummaryController: Error while reading .gitignore: %@", error);
	}
	
	
	{
		NSArray* paths = [self.userInfo objectForKey:@"pathsForGitIgnore"];
		
		if (paths.count > 0)
		{
			gitignoreContents = [gitignoreContents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSUInteger length = gitignoreContents.length;
			NSString* additionalSpace = (length > 0 ? @"\n" : @"");
			NSString* appendix = [paths componentsJoinedByString:@"\n"];
			gitignoreContents = [gitignoreContents stringByAppendingFormat:@"%@%@\n", additionalSpace, appendix];
			[self.gitignoreTextView setString:gitignoreContents];
			NSRange selectionRange = NSMakeRange(length + additionalSpace.length, appendix.length);
			[self.gitignoreTextView setSelectedRange:selectionRange];
			[self.gitignoreTextView scrollRangeToVisible:selectionRange];
		}
		else
		{
			[self.gitignoreTextView setString:gitignoreContents];
		}
	}
	
	
//	[self.repository.libgitRepository.config enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//		NSLog(@"Config: %@ => %@", key, obj);
//	}];
	
	
	// TODO: add label and strings for:
	// ≠ path + disclosure button like in Xcode locations preference
	// + every remote URL
	// + size on disk
	// + number of commits, tags, 
	// - committers etc.
	// - creation date
	
	
}


- (void) save
{
	// Save the remote addresses
	
	//GitConfig* config = self.repository.libgitRepository.config;
	GBGitConfig* config = self.repository.config;
	
	NSUInteger linesCount = MIN(remotes.count, self.fields.count);
	
	if (linesCount == 0) // no remotes yet, let's add a new one.
	{
		if (self.remoteField1.stringValue.length > 0)
		{
			[config setString:self.remoteField1.stringValue forKey:@"remote.origin.url"];
			[config setString:@"+refs/heads/*:refs/remotes/origin/*" forKey:@"remote.origin.fetch"];
		}
		// no else: if remote URL already exists, we'll have something in self.remotes
	}
	else
	{
		[self iterateRemoteLines:^(NSUInteger i, GBRemote *remote, NSTextField *field, NSTextField *label) {
			if (field.stringValue.length > 0)
			{
				[config setString:field.stringValue 
						   forKey:[NSString stringWithFormat:@"remote.%@.url", remote.alias]];
			}
			else // empty string - remove entries
			{
				[config removeKey:[NSString stringWithFormat:@"remote.%@.url", remote.alias]];
				[config removeKey:[NSString stringWithFormat:@"remote.%@.fetch", remote.alias]];
			}
		}];
	}
	
	NSError* error = nil;
	NSString* gitignore = [[self.gitignoreTextView.string copy] autorelease];
	NSString* gitignoreTrimmed = [gitignore stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString* gitignorePath = [self.repository.path stringByAppendingPathComponent:@".gitignore"];
	if (![[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:gitignorePath] && gitignoreTrimmed.length == 0)
	{
		// avoid creating an empty file
	}
	else if (![gitignore writeToFile:gitignorePath
					atomically:YES 
					  encoding:NSUTF8StringEncoding 
						 error:&error])
	{
		NSLog(@"Error: .gitignore update failed: %@", error);
	}
}

- (void) iterateRemoteLines:(void(^)(NSUInteger i, GBRemote* aRemote, NSTextField* field, NSTextField* label))aBlock
{
	NSUInteger linesCount = MIN(self.remotes.count, self.fields.count);
	for (NSUInteger i = 0; i < linesCount; i++)
	{
		NSTextField* field = [self.fields objectAtIndex:i];
		NSTextField* label = [self.labels objectAtIndex:i];
		GBRemote* remote   = [self.remotes objectAtIndex:i];
		aBlock(i, remote, field, label);
	}
}


#pragma mark Private


//- (void) calculateSize
//{
//	if (calculatingSize)
//	{
//		// Try again after 2 and 4 seconds.
//		double delayInSeconds = 2.0;
//		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//			if (calculatingSize)
//			{
//				double delayInSeconds = 2.0;
//				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//					if (calculatingSize) return;
//					[self calculatingSize];
//				});
//				return;
//			}
//			[self calculatingSize];
//		});
//		return;
//	}
//	
//	calculatingSize = YES;
//	
//	self.sizeField.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Size on disk:", @""), @""];
//	
//	[NSFileManager calculateSizeAtURL:self.repository.url completionHandler:^(long long bytes){
//		double bytesf = (double)bytes;
//		double kbytes = bytesf / 1000.0;
//		double mbytes = kbytes / 1000.0;
//		double gbytes = mbytes / 1000.0;
//		
//		NSString* sizeString = [NSString stringWithFormat:@"%qi %@", bytes, NSLocalizedString(@"bytes", @"")];
//		
//		if (gbytes >= 1.0)
//		{
//			sizeString = [NSString stringWithFormat:@"%0.1f %@", gbytes, NSLocalizedString(@"Gb", @"")];
//		}
//		else if (mbytes >= 1.0)
//		{
//			sizeString = [NSString stringWithFormat:@"%0.1f %@", mbytes, NSLocalizedString(@"Mb", @"")];
//		}
//		else if (kbytes >= 1.0)
//		{
//			sizeString = [NSString stringWithFormat:@"%0.1f %@", kbytes, NSLocalizedString(@"Kb", @"")];
//		}
//		
//		self.sizeField.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Size on disk:", @""), sizeString];
//		
//		calculatingSize = NO;
//	}];
//}

//- (NSString*) inflectNumeric:(NSInteger)i singular:(NSString*)singular plural:(NSString*)plural
//{
//	if (i == 1) return singular;
//	return plural;
//}


//- (void) calculateCommits
//{
//	GBTask* task = [GBTask taskWithRepository:self.repository];
//	
//	NSMutableArray* args = [NSMutableArray arrayWithObject:@"log"];
//	[args addObjectsFromArray:[self.repository.localBranches valueForKey:@"name"]];
//	[args addObject:@"--format=\"%H %ae\""];
//	task.arguments = args;
//	[task launchWithBlock:^{
//		self.statsLineField.stringValue = @"";
//		
//		NSString* output = task.UTF8OutputStripped;
//		if (output.length == 0) return;
//		
//		NSArray* lines = [output componentsSeparatedByString:@"\n"];
//		if (lines.count == 0) return;
//		
//		NSMutableArray* stats = [NSMutableArray array];
//		
//		[stats addObject:[NSString stringWithFormat:@"%d %@", lines.count, [self inflectNumeric:lines.count singular:@"commit" plural:@"commits"]]];
//		
//		NSMutableSet* emails = [NSMutableSet set];
//		
//		for (NSString* line in lines)
//		{
//			NSArray* comps = [line componentsSeparatedByString:@" "];
//			if (comps.count >= 2)
//			{
//				[emails addObject:[comps objectAtIndex:1]];
//			}
//		}
//		
//		if (emails.count > 0)
//		{
//			[stats addObject:[NSString stringWithFormat:@"%d %@", emails.count, [self inflectNumeric:emails.count singular:@"contributor" plural:@"contributors"]]];
//		}
//		
//		if (stats.count > 0)
//		{
//			NSString* statsString = [stats componentsJoinedByString:@", "];
//			self.statsLineField.stringValue = statsString;
//		}
//	}];
//}



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

- (IBAction)openInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:self.repository.url];
}

- (void) didUpdateText:(NSNotification*)notif
{
	self.dirty = YES;
}

@end
