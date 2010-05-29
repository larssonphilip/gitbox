#import "GBModels.h"
#import "GBCommitController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"

@implementation GBCommitController


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder:sender];
}



#pragma mark NSSplitViewDelegate

- (CGFloat) minSplitViewHeaderHeight
{
  return 85.0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  return [self minSplitViewHeaderHeight];
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  return [self view].bounds.size.height - 80.0; // 80 px for changes table height
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:[self minSplitViewHeaderHeight]];
}

@end
