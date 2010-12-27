#import "GBStageMessageHistoryController.h"
#import "GBRepository.h"
#import "GBCommit.h"

@interface GBStageMessageHistoryController ()
@property(nonatomic) NSInteger messageIndex;
@property(nonatomic, copy) NSString* initialMessage;
@end


@implementation GBStageMessageHistoryController

@synthesize repository;
@synthesize textView;
@synthesize initialMessage;
@synthesize email;

@synthesize messageIndex;

- (void) dealloc
{
  self.repository = nil;
  self.textView = nil;
  self.initialMessage = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.messageIndex = -1;
  }
  return self;
}

- (NSString*) nextMessage
{
  if (self.messageIndex <= -1)
  {
    return nil;
  }
  
  if (self.messageIndex == 0)
  {
    self.messageIndex = -1;
    return self.initialMessage;
  }
  
  NSArray* commits = [self.repository commits];
  for (NSInteger index = (NSInteger)(self.messageIndex) - 1; index >= 0 && index < [commits count]; index--)
  {
    GBCommit* commit = [commits objectAtIndex:index];
    if (!self.email || [commit.authorEmail isEqualToString:self.email] || [commit.committerEmail isEqualToString:self.email])
    {
      self.messageIndex = index;
      return commit.message;
    }
  }
  
  self.messageIndex = -1;
  return self.initialMessage;
}


- (NSString*) previousMessage
{
  if (self.messageIndex <= -1)
  {
    self.messageIndex = -1;
    self.initialMessage = [[[self.textView string] copy] autorelease];
  }
  
  NSArray* commits = [self.repository commits];
  for (NSInteger index = self.messageIndex + 1; index < [commits count]; index++)
  {
    GBCommit* commit = [commits objectAtIndex:index];
    if (!self.email || [commit.authorEmail isEqualToString:self.email] || [commit.committerEmail isEqualToString:self.email])
    {
      self.messageIndex = index;
      return commit.message;
    }
  }
  return nil;
}


@end
