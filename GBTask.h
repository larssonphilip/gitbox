#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
{
  GBRepository* repository;
}

@property(assign) GBRepository* repository;

@end
