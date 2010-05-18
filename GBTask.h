#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
{
  GBRepository* repository;
}

@property (nonatomic, assign) GBRepository* repository;

@end
