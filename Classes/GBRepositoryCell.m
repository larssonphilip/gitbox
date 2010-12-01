#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"

@implementation GBRepositoryCell

#define kIconImageWidth		16.0

#define kImageOriginXOffset 3
#define kImageOriginYOffset 1

#define kTextOriginXOffset	2
#define kTextOriginYOffset	2
#define kTextHeightAdjust	4


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
  
  imageFrame.origin.x += kImageOriginXOffset;
  imageFrame.size = imageSize;
  
  if ([theControlView isFlipped])
  {
    imageFrame.origin.y += cellFrame.size.height - imageFrame.size.height + kImageOriginYOffset;
  }
  else
  {
    imageFrame.origin.y += kImageOriginYOffset;
  }
  [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
  
  NSRect newCellFrame = cellFrame;
  newCellFrame.origin.x += kTextOriginXOffset;
  newCellFrame.origin.y += kTextOriginYOffset;
  newCellFrame.size.height -= kTextHeightAdjust;
  
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
