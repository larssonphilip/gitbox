#import "GBModels.h"
#import "GBCommit.h"
#import "GBHistoryTask.h"
#import "NSData+OADataHelpers.h"

@implementation GBHistoryTask

@synthesize commits;
@synthesize branch;
@synthesize limit;
@synthesize skip;

- (NSUInteger) limit
{
  if (limit <= 0) limit = 500;
  return limit;
}

- (void) dealloc
{
  self.commits = nil;
  self.branch = nil;
  [super dealloc];
}

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"rev-list", 
          @"--format=commit %H%ntree %T%nparents %P%nauthorName %an%nauthorEmail %ae%ncommitterName %cn%ncommitterEmail %ce%nauthorDate %ai%n%n%w(10000,4,4)%s%n%n%b",
          [NSString stringWithFormat:@"--max-count=%d", self.limit],
          [NSString stringWithFormat:@"--skip=%d", self.skip],
          [self.branch commitish],
          nil];
}

- (void) didFinish
{
  [super didFinish];
  self.commits = [self commitsFromRawFormatData:self.output];
  [self.branch asyncTaskGotCommits:self.commits];
}


/*
our format (for ease of NSDate integration and name/email parsing):
(git prepends "commit <SHA1>" on its own; seems like a bug, so i don't rely on that for the future versions of git)
 
commit c1909e72952ec6b95f819a4ad8faa8d69f1d961d
commit c1909e72952ec6b95f819a4ad8faa8d69f1d961d
tree 219a1c0a3f7e2500a3fe07ee5a6300cff10e98bb
parents 2381e39e5ff740883b98c5aca019950f9167b67f
authorName Junio C Hamano
authorEmail gitster@pobox.com
committerName Junio C Hamano
committerEmail gitster@pobox.com
authorDate 2010-05-01 22:05:14 -0700
 
    wt-status: fix 'fprintf' compilation warning

    color_fprintf() has the same function signature as fprintf() and newer 
    gcc warns when a non-constant string is fed as the format

    Signed-off-by: Junio C Hamano <gitster@pobox.com>
 
 
commit ddb27a5a6b5ed74c70d56c96592b32eed415d72b
commit ddb27a5a6b5ed74c70d56c96592b32eed415d72b
tree b835a16ef2d995f1628d6d5f280cd1bd6514e216
parents c8c073c4201600b958f5d3bd9e8051b2060bd3f7 ed215b109fc0e352456ea2ef6a0f8375e28466d5
authorName Junio C Hamano
authorEmail gitster@pobox.com
committerName Junio C Hamano
committerEmail gitster@pobox.com
authorDate 2010-05-01 20:23:10 -0700

    Merge branch 'maint'

    * maint:
    index-pack: fix trivial typo in usage string
    git-submodule.sh: properly initialize shell variables
 
 
 */

- (NSArray*) commitsFromRawFormatData:(NSData*)data
{

#define HistoryScanError(msg) {NSLog(@"ERROR: GBHistoryTask parse error: %@", msg); return list;}
  
  NSMutableArray* list = [NSMutableArray arrayWithCapacity:self.limit];
  
  NSArray* lines = [[data UTF8String] componentsSeparatedByString:@"\n"];
  
  NSUInteger lineIndex = 0;
  NSString* line = nil;
#define GBHistoryNextLine { \
  lineIndex++; \
  if (lineIndex < [lines count]) { \
    line = [lines objectAtIndex:lineIndex]; \
  } else { \
    line = nil; \
  } \
}
  NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
  while (lineIndex < [lines count])
  {
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    
    line = [lines objectAtIndex:lineIndex];
    GBCommit* commit = [[GBCommit new] autorelease];
    
    // commit 4d235c8044a638108b67e22f94b2876657130fc8
    if ([line hasPrefix:@"commit "])
    {
      commit.commitId = [line substringFromIndex:7]; // 'commit ' skipped
    }
    else HistoryScanError(@"Expected 'commit <sha1>' line");

    GBHistoryNextLine;
    
    if ([line hasPrefix:@"commit "]) // skip additional commit line
    {
      GBHistoryNextLine;
    }
    
    // tree 715659d7f232f1ecbe19674a16c9b03067f6c9e1
    if ([line hasPrefix:@"tree "])
    {
      commit.treeId = [line substringFromIndex:5]; // 'tree ' skipped
    }
    else HistoryScanError(@"Expected 'tree <sha1>' line");
    
    GBHistoryNextLine;
    
    // parents 8d0ea3117597933610e02907d14b443f8996ca3b[<space> <sha1>[<space> <sha1>[...]]] 
    if ([line hasPrefix:@"parents "])
    {
      commit.parentIds = [[line substringFromIndex:8] componentsSeparatedByString:@" "]; // 'parents ' skipped
    }
    else HistoryScanError(@"Expected 'parents <sha1>[ <sha1>[...]]' line");
    
    GBHistoryNextLine;
    
    // authorName Junio C Hamano
    if ([line hasPrefix:@"authorName "])
    {
      commit.authorName = [line substringFromIndex:11]; // 'authorName ' skipped
    }
    else HistoryScanError(@"Expected 'authorName ...' line");
    
    GBHistoryNextLine;
    
    // authorEmail gitster@pobox.com
    if ([line hasPrefix:@"authorEmail "])
    {
      commit.authorEmail = [line substringFromIndex:12]; // 'authorEmail ' skipped
    }
    else HistoryScanError(@"Expected 'authorEmail ...' line");
    
    GBHistoryNextLine;
    
    // committerName Junio C Hamano
    if ([line hasPrefix:@"committerName "])
    {
    }
    else HistoryScanError(@"Expected 'committerName ...' line");
    
    GBHistoryNextLine;
    
    // committerEmail gitster@pobox.com
    if ([line hasPrefix:@"committerEmail "])
    {
    }
    else HistoryScanError(@"Expected 'committerEmail ...' line");
    
    GBHistoryNextLine;
    
    // authorDate 2010-05-01 20:23:10 -0700
    if ([line hasPrefix:@"authorDate "])
    {
      commit.date = [NSDate dateWithString:[line substringFromIndex:11]]; // 'authorDate ' skipped
    }
    else HistoryScanError(@"Expected 'authorDate ...' line");
    
    GBHistoryNextLine;
    
    NSMutableString* rawBody = [NSMutableString string];
    while (line && [line length] <= 0 || [line hasPrefix:@"    "])
    {
      if ([line length] > 0)
      {
        [rawBody appendString:[line stringByTrimmingCharactersInSet:whitespaceCharacterSet]];
      }
      GBHistoryNextLine;
    }
    
    commit.message = rawBody;
    
    [list addObject:commit];
    
    [pool drain];
  }
  
//  while ([scanner isAtEnd] == NO)
//  {
//    // 1. "commit"
//    // 2. space
//    // 3. sha1
//    // 4. line break
//    
//    // 5. "tree"
//    // 6. space
//    // 7. sha1
//    // 8. line break
//    
//    // 9. "tree"
//    // 10. space
//    // 11. sha1
//    // 12. line break
//    
//    tree 715659d7f232f1ecbe19674a16c9b03067f6c9e1
//    parent 8a65ff7666db1299449a397bab3d39d74b82aa54
//    author Linus Torvalds <torvalds@g5.osdl.org> 1120409924 -0700
//    committer Linus Torvalds <torvalds@g5.osdl.org> 1120409924 -0700
//    
//    Avoid gcc warnings in sha1_file.c
//    
//    A couple of bogus "might be used undefined" warnings are avoided
//    by moving the initializations unnecessarily early.
//    
//  } 
  
  return list;
}

@end
