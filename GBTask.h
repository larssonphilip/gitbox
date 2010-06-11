#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
{
  GBRepository* repository;
  id target;
  SEL action;
}

@property(nonatomic,assign) GBRepository* repository;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;

@end
