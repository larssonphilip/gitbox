#import "GBChange.h"
#import "GBRepository.h"
#import "GBExtractFileTask.h"

#import "GBChangeCell.h"
#import "GBSearchQuery.h"

#import "GBSubmodule.h"

#import "OATask.h"

#import "NSString+OAGitHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSError+OAPresent.h"


#define GBChangeDeveloperDirForOpendiff @"GBChangeDeveloperDirForOpendiff"


@interface GBChange ()
@property(nonatomic, retain) NSImage* cachedSrcIcon;
@property(nonatomic, retain) NSImage* cachedDstIcon;
@property(nonatomic, retain) NSURL* quicklookItemURL;
- (NSImage*) iconForPath:(NSString*)path;
- (NSURL*) temporaryURLForObjectId:(NSString*)objectId optionalURL:(NSURL*)url commitId:(NSString*)aCommitId;
@end



@implementation GBChange {
	BOOL relaunchingOpendiff;
}

@synthesize srcURL;
@synthesize dstURL;
@synthesize statusCode;
@synthesize status;
@synthesize statusScore;
@synthesize srcMode;
@synthesize dstMode;
@synthesize srcRevision;
@synthesize dstRevision;
@synthesize commitId;
@synthesize cachedSrcIcon;
@synthesize cachedDstIcon;
@synthesize quicklookItemURL;
@synthesize searchQuery;
@synthesize highlightedPathSubstrings;
@synthesize containsHighlightedDiffLines;


@synthesize staged;
@synthesize delegate;
@synthesize busy;
@synthesize repository;

+ (GBChange*) dummy
{
	return [[self new] autorelease];
}

- (void) dealloc
{
	[srcURL release];
	[dstURL release];
	[statusCode release];
	[status release];
	[srcMode release];
	[dstMode release];
	[srcRevision release];
	[dstRevision release];
	[commitId release];
	[cachedSrcIcon release];
	[cachedDstIcon release];
	[quicklookItemURL release];
	[searchQuery release];
	[highlightedPathSubstrings release];
	[super dealloc];
}

- (void) setStaged:(BOOL) flag
{
	if (flag == staged) return;
	
	staged = flag;
	
	if (flag)
	{
		[delegate stageChange:self];
	}
	else
	{
		[delegate unstageChange:self];
	}
}

- (void) setStagedSilently:(BOOL) flag
{
	id<GBChangeDelegate> aDelegate = self.delegate;
	self.delegate = nil;
	[self setStaged:flag];
	self.delegate = aDelegate;
}

- (NSString*) description
{
	NSString* pathDesc = [self.fileURL absoluteString];
	if (self.dstURL && self.srcURL && ![self.dstURL isEqual:self.srcURL])
	{
		pathDesc = [NSString stringWithFormat:@"%@->%@", [self.srcURL absoluteString], [self.dstURL absoluteString]];
	}
	return [NSString stringWithFormat:@"<GBChange:%p %@ %@->%@ [%@]>", self, pathDesc, [self.srcRevision substringToIndex:6], [self.dstRevision substringToIndex:6], self.statusCode];
}


#pragma mark Interrogation


+ (NSString*) defaultDiffTool
{
	return @"FileMerge";
}

+ (NSArray*) diffTools
{
	return [NSArray arrayWithObjects:@"FileMerge", 
			@"Kaleidoscope",
			@"Changes", 
			@"Araxis Merge",
			@"BBEdit", 
			@"TextWrangler",
			@"DiffMerge",
			//NSLocalizedString(@"Other (full path to executable):", @"Change"), 
			nil];
}

- (BOOL) isRealChange
{
	// Return NO if both modes, revisions and URLs are the same.
	
	if (self.srcRevision && self.dstRevision &&
		[self.srcRevision isEqualToString:self.dstRevision] &&
		self.srcMode && self.dstMode && 
		[self.srcMode isEqualToString:self.dstMode] &&
		self.srcURL && self.dstURL && 
		[self.srcURL isEqual:self.dstURL])
	{
		return NO;
	}
	
	// Return NO if it's a custom folder icon (weird unignorable Mac file)
	
	if ([[[self.srcURL path] lastPathComponent] isEqualToString:@"Icon\\r"] ||
		[[[self.dstURL path] lastPathComponent] isEqualToString:@"Icon\\r"])
	{
		return NO;
	}

	// Return NO if it's a .DS_Store item.
	
	if ([self.srcURL.path rangeOfString:@".DS_Store"].length > 0)
	{
		return NO;
	}

	return YES;
}

- (NSURL*) fileURL
{
	if (self.dstURL) return self.dstURL;
	return self.srcURL;
}

- (NSImage*) icon
{
	if (self.dstURL) return [self dstIcon];
	return [self srcIcon];
}

- (NSImage*) srcIconOrDstIcon
{
	if (self.srcURL) return [self srcIcon];
	return [self dstIcon];
}

- (NSImage*) iconForPath:(NSString*)path
{
	NSImage* icon = nil;
	if (!self.commitId && [[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	}
	if (!icon)
	{
		NSString* ext = [path pathExtension];
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:ext];      
	}
	return icon;
}

- (NSImage*) srcIcon
{
	if (!self.cachedSrcIcon)
	{
		if ([self isSubmodule])
		{
			self.cachedSrcIcon = [NSImage imageNamed:NSImageNameFolder];
		}
		else
		{
			self.cachedSrcIcon = [self iconForPath:[self.srcURL path]];
		}
	}
	return self.cachedSrcIcon;
}

- (NSImage*) dstIcon
{
	if (!self.cachedDstIcon)
	{
		if ([self isSubmodule])
		{
			self.cachedDstIcon = [NSImage imageNamed:NSImageNameFolder];
		}
		else
		{
			self.cachedDstIcon = [self iconForPath:[self.dstURL path]];
		}
	}
	return self.cachedDstIcon;  
}

- (GBSubmodule*) submodule
{
	for (GBSubmodule* sm in self.repository.submodules)
	{
		if (sm.path && [self.srcURL.relativePath isEqual:sm.path])
		{
			return sm;
		}
	}
	return nil;
}


- (NSString*) statusForStatusCode:(NSString*)aStatusCode
{
	/*
	 Possible status letters are:
	 
	 o   A: addition of a file
	 
	 o   C: copy of a file into a new one
	 
	 o   D: deletion of a file
	 
	 o   M: modification of the contents or mode of a file
	 
	 o   R: renaming of a file
	 
	 o   T: change in the type of the file
	 
	 o   U: file is unmerged (you must complete the merge before it can be committed)
	 
	 o   X: "unknown" change type (most probably a bug, please report it)
	 
	 Status letters C and R are always followed by a score (denoting the percentage of similarity between the source and target of the move or copy), and are the only ones to be so.
	 
	 */
    
	
	if (!aStatusCode || [aStatusCode length] < 1)
	{
		//    if (self.busy)
		//    {
		//      return self.staged ? NSLocalizedString(@"Staging...", @"Change") : NSLocalizedString(@"Unstaging...", @"Change");
		//    }
		//    else
		{
			return NSLocalizedString(@"New file", @"Change");
		}
	}
	
	const char* cstatusCode = [aStatusCode cStringUsingEncoding:NSUTF8StringEncoding];
	char c = *cstatusCode;
	
	//  if (self.busy)
	//  {
	//    BOOL s = self.staged;
	//    if (c == 'D') return NSLocalizedString(@"Restoring...", @"Change");
	//    return s ? NSLocalizedString(@"Staging...", @"Change") : NSLocalizedString(@"Unstaging...", @"Change");
	//  }
	
	if (c == 'A') return NSLocalizedString(@"Added", @"Change");
	if (c == 'C') 
	{
		if (statusScore < 100) return NSLocalizedString(@"Modified", @"Change"); // copy status will be denoted by the arrow between the src and dst
		return NSLocalizedString(@"Copied", @"Change");
	}
	
	if (c == 'D') return NSLocalizedString(@"Deleted", @"Change");
	
	if (c == 'M')
	{
		if ([self isDirtySubmodule])
		{
			return NSLocalizedString(@"Dirty", @"Change");
		}
		if ([self isSubmodule])
		{
			NSString* dstCommitId = [self.dstRevision nonZeroCommitId];
			if (dstCommitId.length > 8)
			{
				return [dstCommitId substringWithRange:NSMakeRange(0, 8)];
			}
			
			// No dst commit id - it's an unstaged submodule, so try to find it and get it's HEAD.
			
			GBSubmodule* submodule = [self submodule];
			if (submodule.commitId.length > 8)
			{
				return [submodule.commitId substringWithRange:NSMakeRange(0, 8)];
			}
		}
		return NSLocalizedString(@"Modified", @"Change");
	}
		
	if (c == 'T') return NSLocalizedString(@"Type changed", @"Change");
	if (c == 'U') return NSLocalizedString(@"Unmerged", @"Change");
	if (c == 'X') return NSLocalizedString(@"Unknown", @"Change");
	if (c == 'R')
	{
		if (statusScore < 100) return NSLocalizedString(@"Modified", @"Change"); // renaming will be denoted by the arrow between the src and dst
		if (self.srcURL && self.dstURL && [[[self.srcURL path] lastPathComponent] isEqualToString:[[self.dstURL path] lastPathComponent]])
		{
			return NSLocalizedString(@"Moved", @"Change");
		}
		return NSLocalizedString(@"Renamed", @"Change");
	}
	
	return aStatusCode;
}

- (void) setStatusCode:(NSString*)aCode
{
	if (statusCode == aCode) return;
	
	[statusCode release];
	statusCode = [aCode copy];
	
	self.status = [self statusForStatusCode:statusCode];
}

- (NSString*) pathStatus
{
	if (self.dstURL)
	{
		return [NSString stringWithFormat:@"%@ → %@", self.srcURL.relativePath, self.dstURL.relativePath];
	}
	return self.srcURL.relativePath;
}

- (BOOL) isAddedFile
{
	return [self.statusCode isEqualToString:@"A"];
}

- (BOOL) isDeletedFile
{
	return [self.statusCode isEqualToString:@"D"];
}

- (BOOL) isUntrackedFile
{
	// Both commits are nulls, this is untracked file
	return (![self.srcRevision nonZeroCommitId] && ![self.dstRevision nonZeroCommitId]);
}

- (BOOL) isMovedOrRenamedFile
{
	return [self.statusCode isEqualToString:@"R"];
}

- (BOOL) isSubmodule
{
	return ([self.srcMode isEqualToString:kGBChangeSubmoduleMode] || [self.dstMode isEqualToString:kGBChangeSubmoduleMode]);
}

- (BOOL) isDirtySubmodule
{
	if (![self isSubmodule]) return NO;
	
	NSString* s = [self.srcRevision nonZeroCommitId];
	NSString* d = [self.dstRevision nonZeroCommitId];
	
	return s && d && [s isEqualToString:d];
}

- (NSComparisonResult) compareByPath:(GBChange*) other
{
	return [self.srcURL.relativePath localizedStandardCompare:other.srcURL.relativePath];
}

- (NSString*) pathForIgnore
{
	return [self fileURL].relativePath;
}

- (GBChange*) nilIfBusy
{
	if (self.busy) return nil;
	return self;
}

- (Class) cellClass
{
	return [GBChangeCell class];
}

- (GBChangeCell*) cell
{
	GBChangeCell* cell = [[self cellClass] cell];
	[cell setRepresentedObject:self];
	[cell setEnabled:YES];
	[cell setSelectable:YES];
	return cell;
}




#pragma mark Actions


- (void) doubleClick:(id)sender
{
	[self.delegate doubleClickChange:self];
}

- (void) launchDiffWithBlock:(void(^)())block
{
	BOOL isRelaunched = relaunchingOpendiff;
	relaunchingOpendiff = NO; // reset here to be sure it's cleaned up before multiple exists down there.
	
	[[self retain] autorelease]; // quick patch to work around the crash when changes are replaced
	
	NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];
	
	// Do nothing for deleted file
	if ([self isDeletedFile])
	{
		return;
	}
	
	// This is untracked file: do nothing
	if ([self isUntrackedFile])
	{
		return;
	}
	
	NSString* leftCommitId = [self.srcRevision nonZeroCommitId];
	NSString* rightCommitId = [self.dstRevision nonZeroCommitId];
		
	NSURL* leftURL  = [self temporaryURLForObjectId:leftCommitId optionalURL:self.srcURL commitId:nil];
	NSURL* rightURL = (rightCommitId ? [self temporaryURLForObjectId:rightCommitId optionalURL:[self fileURL] commitId:nil] : [self fileURL]);
	
	if (!leftURL)
	{
		NSLog(@"ERROR: GBChange: No leftURL for blob %@", leftCommitId);
		return;
	}
	
	if (!rightURL)
	{
		NSLog(@"ERROR: GBChange: No rightURL for blob %@", rightCommitId);
		return;
	}
	
	OATask* task = [OATask task];
	
	NSString* diffTool = [[NSUserDefaults standardUserDefaults] stringForKey:kGBChangeDiffToolKey];
	NSString* diffToolLaunchPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"diffToolLaunchPath"];
	
	if (!diffTool) diffTool = @"FileMerge";
	
	if ([diffTool isEqualToString:@"FileMerge"])
	{
		task.executableName = @"opendiff";
	}
	else if ([diffTool isEqualToString:@"Kaleidoscope"])
	{
		task.executableName = @"ksdiff";
	}
	else if ([diffTool isEqualToString:@"Changes"])
	{
		task.executableName = @"chdiff";
	}
	else if ([diffTool isEqualToString:@"TextWrangler"])
	{
		task.executableName = @"twdiff";
	}
	else if ([diffTool isEqualToString:@"BBEdit"])
	{
		task.executableName = @"bbdiff";
	}
	else if ([diffTool isEqualToString:@"DiffMerge"])
	{
		task.executableName = @"diffmerge";
	}
	else if ([diffTool isEqualToString:@"Araxis Merge"])
	{
		task.executableName = @"compare";
	}
	else if (diffToolLaunchPath)
	{
		if ([fileManager isExecutableFileAtPath:diffToolLaunchPath])
		{
			task.launchPath = diffToolLaunchPath;      
		}
		else
		{
			NSLog(@"ERROR: custom path to diff does not exist: %@; falling back to opendiff.", diffToolLaunchPath); 
			task.executableName = @"opendiff";
		}
	}
	else
	{
		NSLog(@"ERROR: no diff is found or launch path is invalid; TODO: add an error to repository error stack");
		block();
		return;
	}
	
	if (task.executableName && ! task.launchPath)
	{
		NSString* launchPath = [OATask systemPathForExecutable:task.executableName];
		
		if (launchPath)
		{
			task.launchPath = launchPath;
		}
		else
		{
			NSLog(@"GBChange: path for %@ not found", task.executableName);
			NSString* message = [NSString stringWithFormat:
								 NSLocalizedString(@"Cannot find path to %@.", @"Change"), diffTool];
			
			NSString* advice = [NSString stringWithFormat:NSLocalizedString(@"Please install the executable %@ or choose another diff tool in Preferences.", @"Change"), task.executableName];
			
			if ([task.executableName isEqualToString:@"opendiff"])
			{
				advice = NSLocalizedString(@"Please install Xcode (it contains FileMerge.app) or choose another diff tool in Preferences.", @"Change");
			}

			if ([NSAlert prompt:message description:advice ok:NSLocalizedString(@"Open Preferences",@"App")])
			{
			  [NSApp sendAction:@selector(showDiffToolPreferences:) to:nil from:self];
			}
			if (block) block();
			return;
		}
	}
	
	NSString* storedDeveloperDir = [[NSUserDefaults standardUserDefaults] objectForKey:GBChangeDeveloperDirForOpendiff];
	if ([task.executableName isEqualToString:@"opendiff"] && storedDeveloperDir) 
	{
		//NSLog(@"GBChange: using DEVELOPER_DIR=%@", storedDeveloperDir);
		[task setEnvironmentValue:storedDeveloperDir forKey:@"DEVELOPER_DIR"];
	}
	
	//NSLog(@"GBChange: task.launchPath = %@", task.launchPath);
	
	task.currentDirectoryPath = self.repository.path;
	task.arguments = [NSArray arrayWithObjects:[leftURL path], [rightURL path], nil];
	// opendiff will quit in 5 secs
	// It also messes with xcode's PTY so after first launch xcode does not show log (but Console.app does).
	
	//  task.alertExecutableNotFoundBlock = ^(NSString* executable) {
	//    NSString* message = [NSString stringWithFormat:
	//                         NSLocalizedString(@"Cannot find path to %@.", @"Change"), diffTool];
	//    NSString* advice = [NSString stringWithFormat:NSLocalizedString(@"Please install the executable %@, choose another diff tool or specify a path to launcher in Preferences.", @"Change"), task.executableName];
	//
	//    if ([NSAlert prompt:message description:advice ok:NSLocalizedString(@"Open Preferences",@"App")])
	//    {
	//      [NSApp sendAction:@selector(showDiffToolPreferences:) to:nil from:self];
	//    }
	//  };
	
	block = [[block copy] autorelease];
	
	[task launchWithBlock:^{
		
		if (!isRelaunched && 
			[task.executableName isEqualToString:@"opendiff"] && 
			([task.UTF8ErrorAndOutput rangeOfString:@"Error:"].length > 0 ||
			 [task.UTF8ErrorAndOutput rangeOfString:@"launch path not accessible"].length > 0 ||
			 [task.UTF8ErrorAndOutput rangeOfString:@"exception"].length > 0))
		{
			NSLog(@"GBChange: opendiff failed; trying to find appropriate DEVELOPER_DIR");
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:GBChangeDeveloperDirForOpendiff];
			
			// So we couldn't launch opendiff with default settings. 
			// Let's find some DEVELOPER_DIR to supply to the opendiff.
			
			// Try to locate opendiff in Xcode 4.3+ bundle.
			// Starting with 4.3, there's no more /Developer folder and /usr/bin/opendiff does not know where the FileMerge is.
			// We will try to find an Xcode in /Applications/Xcode.app/
			// A problem with launching from Xcode.app/...:
			// 2012-02-22 09:09:43.875 opendiff[6978:60b] exception raised trying to run FileMerge: launch path not accessible
			// 2012-02-22 09:09:43.876 opendiff[6978:60b] Couldn't launch FileMerge
			
			NSString* developerDir = nil;
			
			if ([fileManager isExecutableFileAtPath:@"/Applications/Xcode.app/Contents/Developer/usr/bin/opendiff"])
			{
				developerDir = @"/Applications/Xcode.app/Contents/Developer";
			}
			else // Try to find non-standard Xcode installation.
			{
				NSError *error = nil;
				NSString* applicationsPath = @"/Applications";
				NSArray* appPaths = [fileManager contentsOfDirectoryAtPath:applicationsPath error:&error];
				if (appPaths)
				{
					NSMutableArray* opendiffPaths = [NSMutableArray array];
					for (NSString* name in appPaths)
					{
						// opendiff cannot launch if Xcode path contains space (like "Xcode 4.3.app"), so we filter those paths out.
						if ([name rangeOfString:@"Xcode"].length > 0 && [name rangeOfString:@" "].length == 0)
						{
							NSString* path = [[applicationsPath stringByAppendingPathComponent:name] stringByAppendingPathComponent:@"Contents/Developer/usr/bin/opendiff"];
							if ([fileManager isExecutableFileAtPath:path])
							{
								[opendiffPaths addObject:path];
							}
						}
					}
					if (opendiffPaths.count > 0)
					{
						developerDir = [[[[opendiffPaths objectAtIndex:0] // take the first path, the stable one.
										  stringByDeletingLastPathComponent] // /opendiff
										 stringByDeletingLastPathComponent]  // /bin
										stringByDeletingLastPathComponent];  // /usr
					}
				}
				else
				{
					NSLog(@"GBChange: cannot iterate over /Applications/* in a search of Xcode apps. %@", error);
				}
			}
			
			if (developerDir && ![storedDeveloperDir isEqualToString:developerDir])
			{
				NSLog(@"Storing new DEVELOPER_DIR=%@", developerDir);
				[[NSUserDefaults standardUserDefaults] setObject:developerDir forKey:GBChangeDeveloperDirForOpendiff];
				
				// Relaunching the same task.
				relaunchingOpendiff = YES;
				[self launchDiffWithBlock:block];
				return;
			}
			
			double delayInSeconds = 0.1;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				NSMutableDictionary* dict = [NSMutableDictionary dictionary];
				
				[dict setObject:NSLocalizedString(@"Failed to launch FileMerge", @"") forKey:NSLocalizedDescriptionKey];
				[dict setObject:NSLocalizedString(@"Please install Xcode and its Command Line Components and run this command in Terminal:\nsudo xcode-select -switch /Applications/Xcode.app/Contents/Developer", @"")  forKey:NSLocalizedRecoverySuggestionErrorKey];
				
				[[NSError errorWithDomain:GBErrorDomain code:1 userInfo:dict] present];
			});
		}

		if (block) block();
	}];
}

- (BOOL) validateShowDifference
{
	//NSLog(@"TODO: validateShowDifference: validate availability of the diff tool");
	if ([self isDeletedFile]) return NO;
	if ([self isUntrackedFile]) return NO;
	//if (![self.srcRevision nonZeroCommitId]) return NO; // too strict
	return YES;
}


- (void) revealInFinder
{
	NSString* path = [[self fileURL] path];
	if (path && [[NSFileManager defaultManager] isReadableFileAtPath:path])
	{
		[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
	}
}

- (BOOL) validateRevealInFinder
{
	NSString* path = [[self fileURL] path];
	return path && [[NSFileManager defaultManager] isReadableFileAtPath:path];
}


- (BOOL) validateExtractFile
{
	return !!([self fileURL]);
}

- (NSString*) defaultNameForExtractedFile
{
	return [[[self fileURL] path] lastPathComponent];
}

- (NSString*) uniqueSuffix
{
	NSString* suffix = self.commitId;
	if (!suffix)
	{
		suffix = [self.dstRevision nonZeroCommitId];
	}
	if (!suffix)
	{
		suffix = [self.srcRevision nonZeroCommitId];
	}
	
	if (!suffix) return nil;
	
	suffix = [suffix substringToIndex:8];
	
	return [NSString stringWithFormat:@"-%@", suffix];
}

- (NSString*) nameForExtractedFileWithSuffix
{
	NSString* suffix = [self uniqueSuffix];
	
	if (!suffix)
	{
		return nil;
	}
	
	return [[self defaultNameForExtractedFile] pathWithSuffix:suffix];
}

- (void) extractFileWithTargetURL:(NSURL*)aTargetURL;
{
	NSString* objectId = [self.dstRevision nonZeroCommitId];
	
	if (!objectId)
	{
		objectId = [self.srcRevision nonZeroCommitId];
	}
	
	if (objectId)
	{
		GBExtractFileTask* task = [GBExtractFileTask task];
		task.repository = self.repository;
		task.commitId = self.commitId;
		task.objectId = objectId;
		task.originalURL = [self fileURL];
		task.targetURL = aTargetURL;
		[self.repository launchTaskAndWait:task];
	}
}






#pragma mark NSPasteboardWriting



- (NSObject<NSPasteboardWriting>*) pasteboardItem // for now, respond to pasteboard API by ourselves
{
	return [[self retain] autorelease];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	//NSLog(@"GBChange: pasteboardPropertyListForType:%@", type);
	
	if ([type isEqualToString:(NSString *)kUTTypeFileURL])
	{
		if (self.commitId)
		{
			NSString* objectId = [self.dstRevision nonZeroCommitId];
			if (!objectId)
			{
				objectId = [self.srcRevision nonZeroCommitId];
			}
			NSURL* aURL  = [self temporaryURLForObjectId:objectId optionalURL:[self fileURL] commitId:self.commitId];
			return [[aURL absoluteURL] pasteboardPropertyListForType:type];
		}
		else // not committed change: on stage
		{
			if ([self isDeletedFile])
			{
				NSString* objectId = [self.srcRevision nonZeroCommitId];
				if (!objectId) return nil;
				NSURL* aURL  = [self temporaryURLForObjectId:objectId optionalURL:[self fileURL] commitId:self.commitId];
				return [[aURL absoluteURL] pasteboardPropertyListForType:type];
			}
			else
			{
				return [[[self fileURL] absoluteURL] pasteboardPropertyListForType:type];
			}
		}
	}
	
	if ([type isEqualToString:NSPasteboardTypeString])
	{
		return [[self fileURL] path];
	}
	
	return nil;
}

- (NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	NSString* UTI = [((NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
																		(CFStringRef)[[[self fileURL] path] pathExtension], 
																		NULL)) autorelease];
	NSArray* types = [NSArray arrayWithObjects:
					  UTI,
					  kUTTypeFileURL,
					  NSPasteboardTypeString,
					  nil];
	
	//NSLog(@"GBChange: writableTypesForPasteboard: %@", types);
	
	return types;
}

- (NSPasteboardWritingOptions) writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
	//NSLog(@"GBChange: returning NSPasteboardWritingPromised for type %@", type);
	return NSPasteboardWritingPromised;
}







#pragma mark QLPreviewItem


- (id<QLPreviewItem>) QLPreviewItem
{
	return self; // for now, respond to quicklook preview protocol by ourselves
}

- (void) prepareQuicklookItemWithBlock:(void(^)(BOOL didExtractFile))aBlock
{
	aBlock = [[aBlock copy] autorelease];
	
	NSString* objectId = nil;
	
	if (self.commitId)
	{
		objectId = [self.dstRevision nonZeroCommitId];
		if (!objectId)
		{
			objectId = [self.srcRevision nonZeroCommitId];
		}
	}
	else // not committed change: on stage
	{
		if ([self isDeletedFile])
		{
			objectId = [self.srcRevision nonZeroCommitId];
		}
		else
		{
			self.quicklookItemURL = [self fileURL];
		}
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self.quicklookItemURL path]])
	{
		self.quicklookItemURL = nil;
	}
	
	if (self.quicklookItemURL)
	{
		if (aBlock) aBlock(NO);
		return;
	}
	
	if (!objectId)
	{
		if (aBlock) aBlock(NO);
		return;
	}
	
	GBExtractFileTask* task = [GBExtractFileTask task];
	task.folder = @"QuickLook";
	task.repository = self.repository;
	task.objectId = objectId;
	task.originalURL = [self fileURL];
	[task launchWithBlock:^{
		self.quicklookItemURL = task.targetURL;
		if (aBlock) aBlock(YES);
	}];
}

- (NSURL*) previewItemURL
{
	return self.quicklookItemURL;
}

- (NSString*) previewItemTitle
{
	return [[[[self fileURL] absoluteString] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}






#pragma mark Private



- (NSURL*) temporaryURLForObjectId:(NSString*)objectId optionalURL:(NSURL*)url commitId:(NSString*)aCommitId
{
	if (!objectId) 
	{
		// Create an empty textual file
		NSURL* url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"Empty"]];
		NSError* error = nil;
		[@"" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:&error];
		if (error)
		{
			NSLog(@"Error while creating empty temp file: %@", error);
		}
		return url;
	}
	
	GBExtractFileTask* task = [GBExtractFileTask task];
	task.repository = self.repository;
	task.commitId = aCommitId;
	task.objectId = objectId;
	task.originalURL = url;
	[self.repository launchTaskAndWait:task];
	return task.targetURL;
}


@end
