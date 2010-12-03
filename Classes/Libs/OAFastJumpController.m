#import "OAFastJumpController.h"

@interface OAFastJumpController ()
@property(nonatomic,copy) void(^delayedBlock)();
@property(nonatomic,assign) BOOL isJumping;
@end

@implementation OAFastJumpController

@synthesize delayedBlock;
@synthesize isJumping;

- (void) dealloc
{
  self.delayedBlock = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [super dealloc];
}

+ (id) controller
{
  return [[self new] autorelease];
}

- (void) delayBlockIfNeeded:(void(^)())aBlock
{
  static NSTimeInterval delay = 0.10;
  if (!self.isJumping)
  {
    self.isJumping = YES;
    [self performSelector:@selector(delayedCheck) withObject:nil afterDelay:delay];
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

- (void) delayedCheck
{
  self.isJumping = NO;
  void(^aBlock)() = self.delayedBlock;
  [[aBlock retain] autorelease];
  self.delayedBlock = nil;
  if (aBlock) aBlock();
}


@end
