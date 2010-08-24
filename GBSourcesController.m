#import "GBSourcesController.h"

@implementation GBSourcesController

@synthesize nextViews;

- (void) dealloc
{
  self.nextViews = nil;
  [super dealloc];
}




#pragma mark GBSourcesController



- (GBRepository*) repositoryWithURL:(NSURL*)url
{
  return nil;
}

- (void) addRepository:(GBRepository*)repo
{
}

- (void) selectRepository:(GBRepository*)repo
{
  
}





#pragma mark NSOutlineViewDataSource






@end
