#import "GBModels.h"
#import "GBExtractFileTask.h"
#import "OATask.h"

#import "NSString+OAGitHelpers.h"
#import "NSAlert+OAAlertHelpers.h"

@implementation GBChange

@synthesize srcURL;
@synthesize dstURL;
@synthesize statusCode;
@synthesize status;
@synthesize oldRevision;
@synthesize newRevision;

@synthesize staged;
@synthesize delegate;
@synthesize busy;
@synthesize repository;

- (void) dealloc
{
  self.srcURL = nil;
  self.dstURL = nil;
  self.statusCode = nil;
  self.status = nil;
  self.oldRevision = nil;
  self.newRevision = nil;
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
  return [NSArray arrayWithObjects:@"FileMerge", @"Kaleidoscope", @"Changes", nil];
}

- (NSURL*) fileURL
{
  if (self.dstURL) return self.dstURL;
  return self.srcURL;
}

// TODO: remove this
- (BOOL) isEqual:(GBChange*)other
{
  if (!other) return NO;
  
//  if (staged == other.staged)
//  {
//    // Special case: when both changes are staged, one of them may be a "just staged", without a new revision yet.
//    return (([self.srcURL isEqual:other.srcURL] || (!srcURL && !other.srcURL)) &&
//            ([self.dstURL isEqual:other.dstURL] || (!dstURL && !other.dstURL)));  
//  }
  
  return ([self.oldRevision isEqualToString:other.oldRevision] && 
          [self.newRevision isEqualToString:other.newRevision] &&
          [self.statusCode isEqualToString:other.statusCode] &&
          ([self.srcURL isEqual:other.srcURL] || (!srcURL && !other.srcURL)) &&
          ([self.dstURL isEqual:other.dstURL] || (!dstURL && !other.dstURL)) &&
          staged == other.staged);
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
    if (self.busy)
    {
      return self.staged ? NSLocalizedString(@"Staging...", @"Change") : NSLocalizedString(@"Unstaging...", @"Change");
    }
    else
    {
      return NSLocalizedString(@"Untracked", @"Change");
    }
  }
  
  const char* cstatusCode = [aStatusCode cStringUsingEncoding:NSUTF8StringEncoding];
  char c = *cstatusCode;
  
  if (self.busy)
  {
    BOOL s = self.staged;
    if (c == 'D') return NSLocalizedString(@"Restoring...", @"Change");
    return s ? NSLocalizedString(@"Staging...", @"Change") : NSLocalizedString(@"Unstaging...", @"Change");
  }
  
  if (c == 'A') return NSLocalizedString(@"Added", @"Change");
  if (c == 'C') return NSLocalizedString(@"Copied", @"Change");
  if (c == 'D') return NSLocalizedString(@"Deleted", @"Change");
  if (c == 'M') return NSLocalizedString(@"Modified", @"Change");
  if (c == 'R') return NSLocalizedString(@"Renamed", @"Change");
  if (c == 'T') return NSLocalizedString(@"Type changed", @"Change");
  if (c == 'U') return NSLocalizedString(@"Unmerged", @"Change");
  if (c == 'X') return NSLocalizedString(@"Unknown", @"Change");
  
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

- (BOOL) isDeletedFile
{
  return [self.statusCode isEqualToString:@"D"];
}

- (BOOL) isUntrackedFile
{
  // Both commits are nulls, this is untracked file
  return (![self.oldRevision nonZeroCommitId] && ![self.newRevision nonZeroCommitId]);
}

- (NSComparisonResult) compareByPath:(GBChange*) other
{
  return [self.srcURL.relativePath compare:other.srcURL.relativePath];
}

- (NSString*) pathForIgnore
{
  return [self fileURL].relativePath;
}




#pragma mark Actions


- (NSURL*) temporaryURLForObjectId:(NSString*)objectId optionalURL:(NSURL*)url
{
  GBExtractFileTask* task = [GBExtractFileTask task];
  task.repository = self.repository;
  task.objectId = objectId;
  task.originalURL = url;
  [self.repository launchTaskAndWait:task];
  return task.temporaryURL;
}

- (void) launchComparisonTool:(id)sender
{
  // Do nothing for deleted file
  if ([self isDeletedFile])
  {
    return;
  }

  // This is untracked file: just open the app
  if ([self isUntrackedFile])
  {
    [[NSWorkspace sharedWorkspace] openURL:self.fileURL];
    return;
  }
  
  NSString* leftCommitId = [self.oldRevision nonZeroCommitId];
  NSString* rightCommitId = [self.newRevision nonZeroCommitId];
    
  // Note: using fileURL instead of dstURL so that it defaults to srcURL if no dst defined.
  
  NSURL* leftURL  = (leftCommitId ? [self temporaryURLForObjectId:leftCommitId optionalURL:self.srcURL] : self.srcURL);
  NSURL* rightURL = (rightCommitId ? [self temporaryURLForObjectId:rightCommitId optionalURL:self.fileURL] : self.fileURL);
  
  if (!leftURL)
  {
    NSLog(@"ERROR: No leftURL for blob %@", leftCommitId);
    return;
  }
  
  if (!rightURL)
  {
    NSLog(@"ERROR: No rightURL for blob %@", rightCommitId);
    return;
  }
    
//  NSLog(@"blobs %@ %@", leftCommitId, rightCommitId);
//  NSLog(@"original paths %@ %@", [leftURL path], [rightURL path]);
//  NSLog(@"opendiff %@ %@", [leftURL path], [rightURL path]);
  
  OATask* task = [OATask task];
  task.executableName = @"opendiff";
  
  NSString* diffTool = [[NSUserDefaults standardUserDefaults] stringForKey:@"diffTool"];
  if (!diffTool) diffTool = @"FileMerge";
  if ([diffTool isEqualToString:@"Kaleidoscope"])
  {
    task.executableName = @"ksdiff";
  }
  else if ([diffTool isEqualToString:@"Changes"])
  {
    task.executableName = @"chdiff";
  }
  task.currentDirectoryPath = self.repository.path;
  task.arguments = [NSArray arrayWithObjects:[leftURL path], [rightURL path], nil];
  // opendiff will quit in 5 secs
  // It also messes with xcode's PTY so after first launch xcode does not show log (but Console.app does).
  task.avoidIndicator = YES;
  task.alertExecutableNotFoundBlock = ^(NSString* executable) {
    NSString* message = [NSString stringWithFormat:
                         NSLocalizedString(@"Cannot find path to %@.", @""), diffTool];
    NSString* advice = [NSString stringWithFormat:NSLocalizedString(@"Please install the executable %@, choose another diff tool or specify a path to launcher in Preferences.", @""), task.executableName];

    if ([NSAlert prompt:message description:advice ok:NSLocalizedString(@"Open Preferences",@"")])
    {
      [NSApp sendAction:@selector(showDiffToolPreferences:) to:nil from:self];
    }
  };
  [task launchWithBlock:^{
    
  }];
}

- (void) revealInFinder:(id)sender
{
  NSString* path = [self.fileURL path];
  if (path && ![self isDeletedFile])
  {
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
  }
}

- (BOOL) validateRevealInFinder:(id)sender
{
  return (self.fileURL && ![self isDeletedFile]);
}


- (void) deleteFile
{
  if (!self.staged)
  {
    if ([self isUntrackedFile])
    {
      [self moveToTrash];
    }
    else
    {
      [self gitRm];
    }    
  }
}

- (void) moveToTrash
{
  NSString* aPath = self.fileURL.path;
  NSString* sourceDir = [aPath stringByDeletingLastPathComponent]; 
  NSString* aName = [aPath lastPathComponent];
  NSInteger tag;
  [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
                                               source:sourceDir
                                          destination:@""
                                                files:[NSArray arrayWithObject:aName]
                                                  tag:&tag];  
}

- (void) gitRm
{
  [[self.repository task]
   launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"rm", self.fileURL.path, nil]];
}

@end
