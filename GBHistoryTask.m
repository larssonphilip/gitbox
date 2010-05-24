#import "GBModels.h"
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
          @"--format=raw",
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
 raw format:
 
 commit 4d235c8044a638108b67e22f94b2876657130fc8
 tree 715659d7f232f1ecbe19674a16c9b03067f6c9e1
 parent 8a65ff7666db1299449a397bab3d39d74b82aa54
 author Linus Torvalds <torvalds@g5.osdl.org> 1120409924 -0700
 committer Linus Torvalds <torvalds@g5.osdl.org> 1120409924 -0700
 
     Avoid gcc warnings in sha1_file.c
   
     A couple of bogus "might be used undefined" warnings are avoided
     by moving the initializations unnecessarily early.
 
 commit 34155390a576d8124e0adc864aaf2f11bbf5168b
 tree 4918235816314f1d9981456cb05e395b6030c035
 parent 8d0ea3117597933610e02907d14b443f8996ca3b
 author Sven Verdoolaege <skimo@kotnet.org> 1120388526 +0200
 committer Sven Verdoolaege <skimo@kotnet.org> 1120388526 +0200
 
     Support :ext: access method.
 
 
 */

- (NSArray*) commitsFromRawFormatData:(NSData*)data
{

#define HistoryScanError(msg) {NSLog(@"ERROR: GBHistoryTask parse error: %@", msg); return list;}
  
  NSMutableArray* list = [NSMutableArray arrayWithCapacity:self.limit];
  NSScanner* scanner = [NSScanner scannerWithString:[data UTF8String]];
  
  [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
  
//  while ([scanner isAtEnd] == NO)
//  {
//    
//  } 
  
  return list;
}

@end
