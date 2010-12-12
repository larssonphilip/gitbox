#import "OABlockGroup.h"

@interface OABlockGroup ()
@property(nonatomic, copy) void(^block)();
@property(nonatomic, assign) BOOL isWrapped;
@property(nonatomic, assign) int counter;
@end

@implementation OABlockGroup
@synthesize block;
@synthesize isWrapped;
@synthesize counter;

+ (void) groupBlock:(void(^)(OABlockGroup*))groupBlock continuation:(void(^)())continuationBlock
{
  OABlockGroup* group = [[self new] autorelease];
  group.block = continuationBlock;
  group.isWrapped = YES;
  [group enter];
  groupBlock(group);
  [group leave];
}

- (void) dealloc
{
  self.block = nil;
  [super dealloc];
}

- (void) enter
{
  NSAssert(isWrapped, @"OABlockGroup: enter called without wrapping a block");
  counter++;
}

- (void) leave
{
  counter--;
  if (counter == 0)
  {
    if (self.block) self.block();
    self.block = nil;
  }
}

@end
