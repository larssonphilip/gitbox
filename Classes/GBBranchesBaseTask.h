#import "GBTask.h"

@interface GBBranchesBaseTask : GBTask
{
  NSArray* branches;
  NSArray* tags;
}
@property(nonatomic,retain) NSArray* branches;
@property(nonatomic,retain) NSArray* tags;

@end
