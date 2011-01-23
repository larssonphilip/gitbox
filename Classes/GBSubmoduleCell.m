#import "GBSubmoduleCell.h"
#import "GBSubmodule.h"
#import "GBRepositoryController.h"

@interface GBSubmoduleCell ()
- (GBSubmodule*) submodule;
- (GBBaseRepositoryController*) repositoryController;
@end

@implementation GBSubmoduleCell


#pragma mark GBSidebarCell


- (NSImage*) icon
{
  return [NSImage imageNamed:@"GBSidebarSubmoduleIcon.png"];
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
  // TODO: draw "download" button
  // TODO: draw sharing icon
  return [super drawExtraFeaturesAndReturnRemainingRect:rect];
}


#pragma mark Private

- (GBSubmodule*) submodule
{
  return (GBSubmodule*)[self representedObject];
}

- (GBBaseRepositoryController*) repositoryController
{
  return [[self submodule] repositoryController];
}

@end
