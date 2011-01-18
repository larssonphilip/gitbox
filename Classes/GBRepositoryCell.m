#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"
#import "CGContext+OACGContextHelpers.h"
#import "GBLightScroller.h"
#import "GBSidebarOutlineView.h"


@interface GBRepositoryCell ()
- (GBBaseRepositoryController*) repositoryController;
@end

@implementation GBRepositoryCell


#pragma mark GBSidebarCell


- (NSImage*) icon
{
  return [[NSWorkspace sharedWorkspace] iconForFile:[[[self repositoryController] url] path]];
}


- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
  // TODO: draw sharing icon
  return [super drawExtraFeaturesAndReturnRemainingRect:rect];
}


#pragma mark Private


- (GBBaseRepositoryController*) repositoryController
{
  return (GBBaseRepositoryController*)[self representedObject];
}

@end
