#import "GBSubmoduleCell.h"
#import "GBSubmodule.h"
#import "GBSidebarItem.h"
#import "GBRepositoryController.h"

@interface GBSubmoduleCell ()
@property(nonatomic, retain, readonly) GBSubmodule* submodule;
- (GBBaseRepositoryController*) repositoryController;
- (NSRect) drawDownloadButtonAndReturnRemainingRect:(NSRect)rect;
@end

@implementation GBSubmoduleCell


#pragma mark GBSidebarCell


- (NSImage*) image
{
  if ([[self submodule] status] == GBSubmoduleStatusNotCloned)
  {
    return [NSImage imageNamed:@"GBSidebarSubmoduleMissingIcon.png"];
  }
  return [NSImage imageNamed:@"GBSidebarSubmoduleIcon.png"];
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
  if (![self.submodule isCloned] && ![self.sidebarItem visibleSpinning])
  {
    return [self drawDownloadButtonAndReturnRemainingRect:rect];
  }
  return [super drawExtraFeaturesAndReturnRemainingRect:rect];
}



#pragma mark Private


- (NSRect) drawDownloadButtonAndReturnRemainingRect:(NSRect)rect
{
  return rect;
}

- (GBSubmodule*) submodule
{
  return (GBSubmodule*)[self.sidebarItem object];
}

- (GBBaseRepositoryController*) repositoryController
{
  return self.submodule.repositoryController;
}

@end
