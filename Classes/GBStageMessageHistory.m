#import "GBStageMessageHistory.h"
#import "GBRepository.h"

@interface GBStageMessageHistory ()
@property(nonatomic) NSInteger messageIndex;
@property(nonatomic, copy) NSString* initialMessage;
@end


@implementation GBStageMessageHistory

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
  
  return nil;
}

- (NSString*) previousMessage
{
  if (self.messageIndex <= -1)
  {
    self.initialMessage = [[[self.textView string] copy] autorelease];
  }
  
  NSUInteger index = self.messageIndex + 1;
  NSString* msg = nil;
  NSArray* commits = [self.repository commits];
  while ((index+1) < [commits count])
  {
    index++;
  }
  
  if (msg)
  {
    
  }
  return msg;
}


@end
