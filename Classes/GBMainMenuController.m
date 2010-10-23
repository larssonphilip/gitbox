#import "GBMainMenuController.h"

@implementation GBMainMenuController

@synthesize mainMenu;
@synthesize window;

- (void) dealloc
{
  self.mainMenu = nil;
  self.window = nil;
  [super dealloc];
}





@end
