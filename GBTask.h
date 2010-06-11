#import "OATask.h"

@class GBRepository;
@interface GBTask : OATask
{
  GBRepository* repository;
}

@property(nonatomic,assign) GBRepository* repository;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;

@end
