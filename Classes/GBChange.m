#import "GBModels.h"
#import "GBExtractFileTask.h"

#import "GBChangeCell.h"

#import "OATask.h"

#import "NSString+OAGitHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@interface GBChange ()
@property(nonatomic, retain) NSImage* cachedSrcIcon;
@property(nonatomic, retain) NSImage* cachedDstIcon;
- (NSImage*) iconForPath:(NSString*)path;
@end



@implementation GBChange

@synthesize srcURL;
@synthesize dstURL;
@synthesize statusCode;
@synthesize status;
@synthesize oldRevision;
@synthesize newRevision;
@synthesize commitId;
@synthesize cachedSrcIcon;
@synthesize cachedDstIcon;


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
  self.srcURL = nil;
  self.dstURL = nil;
  self.statusCode = nil;
  self.status = nil;
  self.oldRevision = nil;
  self.newRevision = nil;
  self.commitId = nil;
  self.cachedSrcIcon = nil;
  self.cachedDstIcon = nil;

  [super dealloc];
}

- (void) setStaged:(BOOL) flag
{
  if (flag != staged)
  {
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
  [self update];
}

- (void) setStagedSilently:(BOOL) flag
{
  id<GBChangeDelegate> aDelegate = self.delegate;
  self.delegate = nil;
  [self setStaged:flag];
  self.delegate = aDelegate;
}



#pragma mark Interrogation



+ (NSArray*) diffTools
{
  return [NSArray arrayWithObjects:@"FileMerge", 
          @"Kaleidoscope",
          @"Changes", 
          @"Araxis Merge",
          @"BBEdit", 
          @"TextWrangler", 
          //NSLocalizedString(@"Other (full path to executable):", @"Change"), 
          nil];
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
    self.cachedSrcIcon = [self iconForPath:[self.srcURL path]];
  }
  return self.cachedSrcIcon;
}

- (NSImage*) dstIcon
{
  if (!self.cachedDstIcon)
  {
    self.cachedDstIcon = [self iconForPath:[self.dstURL path]];
  }
  return self.cachedDstIcon;  
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
  if (c == 'C') return NSLocalizedString(@"Copied", @"Change");
  if (c == 'D') return NSLocalizedString(@"Deleted", @"Change");
  if (c == 'M') return NSLocalizedString(@"Modified", @"Change");
  if (c == 'T') return NSLocalizedString(@"Type changed", @"Change");
  if (c == 'U') return NSLocalizedString(@"Unmerged", @"Change");
  if (c == 'X') return NSLocalizedString(@"Unknown", @"Change");
  if (c == 'R')
  {
    if (self.srcURL && self.dstURL && [[[self.srcURL path] lastPathComponent] isEqualToString:[[self.dstURL path] lastPathComponent]])
    {
      return NSLocalizedString(@"Moved", @"Change");
    }
    return NSLocalizedString(@"Renamed", @"Change");
  }
  
  return aStatusCode;
}

- (void) update
{
  self.status = [self statusForStatusCode:self.statusCode];
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
  return (![self.oldRevision nonZeroCommitId] && ![self.newRevision nonZeroCommitId]);
}

- (BOOL) isMovedOrRenamedFile
{
  return [self.statusCode isEqualToString:@"R"];
}


- (NSComparisonResult) compareByPath:(GBChange*) other
{
  return [self.srcURL.relativePath compare:other.srcURL.relativePath];
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


- (NSURL*) temporaryURLForObjectId:(NSString*)objectId optionalURL:(NSURL*)url commitId:(NSString*)aCommitId
{
  GBExtractFileTask* task = [GBExtractFileTask task];
  task.repository = self.repository;
  task.commitId = aCommitId;
  task.objectId = objectId;
  task.originalURL = url;
  [self.repository launchTaskAndWait:task];
  return task.targetURL;
}



- (void) doubleClick:(id)sender
{
  [self launchDiffWithBlock:^{}];
}

- (void) launchDiffWithBlock:(void(^)())block
{
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
  
  NSString* leftCommitId = [self.oldRevision nonZeroCommitId];
  NSString* rightCommitId = [self.newRevision nonZeroCommitId];
  
  if (!leftCommitId)
  {
    return;
  }
  
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
  
  NSString* diffTool = [[NSUserDefaults standardUserDefaults] stringForKey:@"diffTool"];
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
  else if ([diffTool isEqualToString:@"Araxis Merge"])
  {
    task.executableName = @"compare";
  }
  else if (diffToolLaunchPath)
  {
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:diffToolLaunchPath])
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
  [task launchWithBlock:block];
}

- (BOOL) validateShowDifference
{
  NSLog(@"TODO: validateShowDifference: validate availability of the diff tool");
  if ([self isDeletedFile]) return NO;
  if ([self isUntrackedFile]) return NO;
  if (![self.oldRevision nonZeroCommitId]) return NO;
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
    suffix = [self.newRevision nonZeroCommitId];
  }
  if (!suffix)
  {
    suffix = [self.oldRevision nonZeroCommitId];
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
  NSString* objectId = [self.newRevision nonZeroCommitId];
  
  if (!objectId)
  {
    objectId = [self.oldRevision nonZeroCommitId];
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

//- (NSString*) nameForExtractedFileAtDestination:(NSURL*)folderURL
//{
//  NSLog(@"GBChange: nameForExtractedFileAtDestination:%@", folderURL);
//  
//  if (![self fileURL]) return nil;
//  
//  NSString* name = [[[self fileURL] path] lastPathComponent];
//  
//  if (!name) return nil;
//  
//  NSString* folderPath = [folderURL path];
//  NSString* fullPath = [folderPath stringByAppendingPathComponent:name];
//  
//  if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:NULL])
//  {
//    NSString* sfx = [self uniqueSuffix];
//    if (!sfx)
//    {
//      return nil;
//    }
//    fullPath = [fullPath pathWithSuffix:sfx];
//  }
//  
//  NSLog(@"GBChange: extracting file: %@", fullPath);
//  
//  [self extractFileWithTargetURL:[NSURL fileURLWithPath:fullPath]];
//  
//  return [fullPath lastPathComponent];
//}




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
      NSString* objectId = [self.newRevision nonZeroCommitId];
      if (!objectId)
      {
        objectId = [self.oldRevision nonZeroCommitId];
      }
      NSURL* aURL  = [self temporaryURLForObjectId:objectId optionalURL:[self fileURL] commitId:self.commitId];
      return [[aURL absoluteURL] pasteboardPropertyListForType:type];
    }
    else // not committed change: on stage
    {
      if ([self isDeletedFile])
      {
        NSString* objectId = [self.oldRevision nonZeroCommitId];
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
    return [[self fileURL] absoluteString];
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




@end
