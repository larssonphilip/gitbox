#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"

@implementation GBRepositoryCell

#define kIconImageWidth		16.0



+ (CGFloat) cellHeight
{
  return 32.0;
}

- (id)init
{
  self = [super init];
  [self setEditable:NO];
  [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [self setLineBreakMode:NSLineBreakByTruncatingTail];
  return self;
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:[[[self repositoryController] url] path]];
  
  NSSize imageSize = NSMakeSize(kIconImageWidth, kIconImageWidth);
  [image setSize:imageSize];
  
  NSRect imageFrame;
  
  NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
  
  imageFrame.origin.x += 0;
  imageFrame.size = imageSize;
  
  if ([theControlView isFlipped])
  {
    imageFrame.origin.y += cellFrame.size.height - imageFrame.size.height + 2;
  }
  else
  {
    imageFrame.origin.y += 1;
  }
  [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
  
  NSRect newCellFrame = cellFrame;
  newCellFrame.origin.x += 1;
  newCellFrame.origin.y += 3;
  newCellFrame.size.height -= 4;
  
  [super drawInteriorWithFrame:newCellFrame inView:theControlView];
}

- (id) copyWithZone:(NSZone *)zone
{
  GBRepositoryCell* c = [super copyWithZone:zone];
  [c setRepresentedObject:[self representedObject]];
  return c;
}

- (GBBaseRepositoryController*) repositoryController
{
  return (GBBaseRepositoryController*)[self representedObject];
}

@end
