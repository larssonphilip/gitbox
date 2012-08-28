#import "OAFastJumpController.h"

@interface OAFastJumpController ()
@property(nonatomic,copy) void(^delayedBlock)();
@property(nonatomic,assign) BOOL isJumping;
- (void) callBlockAndClear;
@end

@implementation OAFastJumpController

@synthesize delayedBlock;
@synthesize isJumping;
@synthesize flushInterval;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

+ (id) controller
{
  return [self new];
}

- (void) delayBlockIfNeeded:(void(^)())aBlock
{
  static NSTimeInterval delay = 0.10;
  if (!self.isJumping)
  {
    self.isJumping = YES;
    
    if (self.flushInterval > 0) [self performSelector:@selector(delayedCheck) withObject:nil afterDelay:self.flushInterval];
    [self performSelector:@selector(regularCheck) withObject:nil afterDelay:delay];
    aBlock();
  }
  else
  {
    self.delayedBlock = aBlock;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedCheck) object:nil];
    [self performSelector:@selector(delayedCheck) withObject:nil afterDelay:delay];
  }
}

- (void) cancel
{
  self.isJumping = NO;
  self.delayedBlock = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) flush
{
  [self callBlockAndClear];
  [self cancel];
}

- (void) delayedCheck
{
  self.isJumping = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(regularCheck) object:nil];
  [self callBlockAndClear];
}

- (void) regularCheck
{
  [self callBlockAndClear];
  if (self.isJumping && self.flushInterval > 0)
  {
    [self performSelector:_cmd withObject:nil afterDelay:self.flushInterval];
  }
}

- (void) callBlockAndClear
{
  void(^aBlock)() = self.delayedBlock;
	GB_RETAIN_AUTORELEASE(aBlock);
  self.delayedBlock = nil;
  if (aBlock) aBlock();  
}


@end
