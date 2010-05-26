#import "GBModels.h"
#import "GBExtractFileTask.h"
#import "OATask.h"
#import "OATaskManager.h"

#import "NSString+OAGitHelpers.h"

@implementation GBChange

@synthesize srcURL;
@synthesize dstURL;
@synthesize statusCode;
@synthesize oldRevision;
@synthesize newRevision;
@synthesize staged;

@synthesize repository;

- (void) dealloc
{
  self.srcURL = nil;
  self.dstURL = nil;
  self.statusCode = nil;
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
      [self.repository.stage stageChange:self];
    }
    else
    {
      [self.repository.stage unstageChange:self];
    }
  }
}



#pragma mark Interrogation



- (NSURL*) fileURL
{
  if (self.dstURL) return self.dstURL;
  return self.srcURL;
}

- (BOOL) isEqual:(GBChange*)other
{
  if (!other) return NO;
  return ([self.oldRevision isEqualToString:other.oldRevision] && 
          [self.newRevision isEqualToString:other.newRevision] &&
          [self.statusCode isEqualToString:other.statusCode] &&
          ([self.srcURL isEqual:other.srcURL] || (!srcURL && !other.srcURL)) &&
          ([self.dstURL isEqual:other.dstURL] || (!dstURL && !other.dstURL)) &&
          staged == other.staged);
}

- (NSString*) status
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
  
  if (!self.statusCode || [self.statusCode length] < 1) return NSLocalizedString(@"Untracked", @"");
  
  const char* cstatusCode = [self.statusCode cStringUsingEncoding:NSUTF8StringEncoding];
  char c = *cstatusCode;
  if (c == 'A') return NSLocalizedString(@"Added", @"");
  if (c == 'C') return NSLocalizedString(@"Copied", @"");
  if (c == 'D') return NSLocalizedString(@"Deleted", @"");
  if (c == 'M') return NSLocalizedString(@"Modified", @"");
  if (c == 'R') return NSLocalizedString(@"Renamed", @"");
  if (c == 'T') return NSLocalizedString(@"Type changed", @"");
  if (c == 'U') return NSLocalizedString(@"Unmerged", @"");
  if (c == 'X') return NSLocalizedString(@"Unknown", @"");
  
  return self.statusCode;
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





#pragma mark Actions


- (NSURL*) temporaryURLForObjectId:(NSString*)objectId optionalURL:(NSURL*)url
{
  GBExtractFileTask* task = [GBExtractFileTask task];
  task.repository = self.repository;
  task.objectId = objectId;
  task.originalURL = url;
  [task launchAndWait];
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
  task.currentDirectoryPath = self.repository.path;
  task.arguments = [NSArray arrayWithObjects:[leftURL path], [rightURL path], nil];
  // opendiff waits for FileMerge.app to exit, so we should kill it
  task.terminateTimeout = 2.0;
  task.avoidIndicator = YES;
  [task launch];
  
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

- (void) unstage
{
  [[self.repository task] 
   launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"reset", @"--", self.fileURL.path, nil]];
}

- (void) revert
{
  [[self.repository task] 
   launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"HEAD", @"--", self.fileURL.path, nil]];
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
