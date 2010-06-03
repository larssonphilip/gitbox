#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
{
  GBRepository* repository;
}

@property(assign) GBRepository* repository;

@property(assign) id target;
@property(assign) SEL action;

@end
