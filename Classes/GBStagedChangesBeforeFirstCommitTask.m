#import "GBModels.h"
#import "GBStagedChangesBeforeFirstCommitTask.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"

@implementation GBStagedChangesBeforeFirstCommitTask

- (NSArray*) arguments
{
  // This always returns a proper results even before the first commit exists.
  // Comparing to diff-index this does not return src object id.
  // Because of that, this class is used only when diff-index fails which means:
  // - either we don't have any staged changes,
  // - or we don't have a HEAD yet.
  return [@"ls-files --cached --stage" componentsSeparatedByString:@" "];
}

- (void) initializeChange:(GBChange*)change
{
  change.staged = YES; // set this before fully initialized and cannot trigger update
  [super initializeChange:change];
}

- (NSArray*) changesFromDiffOutput:(NSData*) data
{
  /*
   $ git ls-files --stage
   
   An output line is formatted this way:
   
   <mode> <space> <object-id> <space> <stage-number> <tab> <escaped-file-path>
   
   100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	deleted
   100644 2e0996000b7e9019eabcad29391bf0f5c7702f0b 0	modified
   100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	"quoted\\'\""
   100644 b297ab5f7f1169a202469a6f398c6f2d6f38e013 0	renamed
   100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	staged
   100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	яблоко на морозе
   
   That is, from the left to the right:
   
   1. mode for "src"
   
   2. a space.
   
   3. sha1 for the object
   
   4. a space.
   
   5. numerical stage number
   
   6. tab (\t)
   
   7. file path, escaped
   
   8. an LF or a NUL when -z option is used, to terminate the record.
      
   When -z option is not used, TAB, LF, and backslash characters in pathnames are represented as \t, \n, and \\, respectively.
   
   */
#define ChangesScanError(msg) {NSLog(@"ERROR: GBStagedChangesBeforeFirstCommitTask parse error: %@", msg); return aChanges;}
  
  NSMutableArray* aChanges = [NSMutableArray array];
  NSScanner* scanner = [NSScanner scannerWithString:[data UTF8String]];
  
  [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
  
  while ([scanner isAtEnd] == NO)
  { 
    //  1. mode for "src"
    if (![scanner scanUpToString:@" " intoString:NULL]) ChangesScanError(@"Expected file mode");
    
    //  2. a space.
    if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 2");
    
    //  3. sha1 for the object
    NSString* newRevision = nil;
    if (![scanner scanUpToString:@" " intoString:&newRevision]) ChangesScanError(@"Expected object SHA1");
    
    // 4. a space.
    if (![scanner scanString:@" " intoString:NULL]) ChangesScanError(@"Expected space 4");
    
    // 5. numerical stage number followed by tab
    NSString* stageNumber = nil;
    if (![scanner scanUpToString:@"\t" intoString:&stageNumber]) ChangesScanError(@"Expected stage number");
    
    // 6. a tab or a NUL when -z option is used.
    if (![scanner scanString:@"\t" intoString:NULL]) ChangesScanError(@"Expected tab 6");
    
    NSString* srcPath = nil;
    
    // 7. path for "dst"
    if (![scanner scanUpToString:@"\n" intoString:&srcPath]) ChangesScanError(@"Expected src path with LF");
    srcPath = [srcPath stringByUnescapingGitFilename];
    
    // 8. an LF or a NUL when -z option is used, to terminate the record.
    if (![scanner scanString:@"\n" intoString:NULL]) ChangesScanError(@"Expected LF");
    
    GBChange* aChange = [[GBChange new] autorelease];
    [self initializeChange:aChange];
    aChange.repository = self.repository;
    aChange.statusCode = @"A";
    aChange.oldRevision = @"0000000000000000000000000000000000000000";
    aChange.newRevision = newRevision;
    aChange.srcURL = [NSURL URLWithString:[srcPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:self.repository.url];
    [aChanges addObject:aChange];
    //NSLog(@"Added change %@ %@->%@ %@", statusCode, oldRevision, newRevision, srcPath);
  }
  return aChanges;
}
@end
