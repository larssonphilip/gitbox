
#import "GBRepository.h"
#import "GBRef.h"

#import "GBMainWindowController.h"
#import "GBToolbarController.h"
#import "GBSourcesController.h"

#import "GBRepositoryController.h"

@implementation GBRepositoryController

@synthesize repository;
@synthesize windowController;

- (void) dealloc
{
  self.repository = nil;
  self.windowController = nil;
  [super dealloc];
}


- (void) selectRepository:(GBRepository*) repo
{
  self.repository = repo;
  [self.windowController didSelectRepository:repo];
}

- (void) checkoutRef:(GBRef*) ref
{
  
}





@end
