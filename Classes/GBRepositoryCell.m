#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"
#import "CGContext+OACGContextHelpers.h"
#import "GBLightScroller.h"


#define kIconImageWidth		16.0


@interface GBRepositoryCell ()
- (NSRect) drawBadge:(NSString*)badge inTitleFrame:(NSRect)frame;
- (void) drawTitleInFrame:(NSRect)frame;
- (void) drawSubtitleInFrame:(NSRect)frame;
@end

@implementation GBRepositoryCell

@synthesize isForeground;
@synthesize isFocused;

+ (CGFloat) cellHeight
{
  return 22.0;
//  return 35.0;
}

- (id)init
{
  self = [super init];
  [self setEditable:NO];
  [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [self setLineBreakMode:NSLineBreakByTruncatingTail];
  return self;
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


- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  NSWindow* window = [theControlView window];
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  self.isForeground = [window isMainWindow];

  NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:[[[self repositoryController] url] path]];
  
  NSSize imageSize = NSMakeSize(kIconImageWidth, kIconImageWidth);
  [image setSize:imageSize];
  
  NSRect imageFrame;
  NSRect textualFrame;
  
  NSDivideRect(cellFrame, &imageFrame, &textualFrame, 3 + imageSize.width, NSMinXEdge);
  
  imageFrame.origin.x += 0;
  imageFrame.size = imageSize;
  
  if ([theControlView isFlipped])
  {
    imageFrame.origin.y += imageFrame.size.height + 2;
  }
  else
  {
    imageFrame.origin.y += 1;
  }
  [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
  
  
  textualFrame.origin.x += 3;
  textualFrame.origin.y += 4;
  textualFrame.size.height -= 4;
  textualFrame.size.width -= [GBLightScroller width] + 1; // make some room for scrollbar
  
  
  
  // Title & subtitle
  
  
  NSString* badgeLabel = [[self repositoryController] badgeLabel];
  if (badgeLabel && [badgeLabel length] > 0)
  {
    NSRect badgeFrame = [self drawBadge:badgeLabel inTitleFrame:textualFrame];
    textualFrame.size.width = badgeFrame.origin.x - textualFrame.origin.x - 2.0;
  }
  
  NSRect titleFrame;
  NSRect subtitleFrame;
  
  NSDivideRect(textualFrame, &titleFrame, &subtitleFrame, 14.0, NSMinYEdge);
  
//  [[NSColor blueColor] set];
//  [NSBezierPath fillRect:titleFrame];
//  [[NSColor redColor] set];
//  [NSBezierPath fillRect:subtitleFrame];
  
  [self drawTitleInFrame:titleFrame];
  [self drawSubtitleInFrame:subtitleFrame];
  
  
//  [super drawInteriorWithFrame:textualFrame inView:theControlView];
}








- (NSRect) drawBadge:(NSString*)badge inTitleFrame:(NSRect)frame
{
  NSStringDrawingOptions drawingOptions = NSStringDrawingDisableScreenFontSubstitution;
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
//  NSFontDescriptor* descriptor = [NSFontDescriptor]
  
  NSFont* font = [NSFont boldSystemFontOfSize:11.0];
  NSColor* textColor = [NSColor whiteColor];
  
  if ([self isHighlighted])
  {
    textColor = [NSColor colorWithCalibratedHue:217.0/360.0 saturation:0.40 brightness:0.70 alpha:1.0];
    if (!self.isForeground)
    {
      textColor = [NSColor grayColor];
    }
  }
  
	NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      textColor, NSForegroundColorAttributeName,
                                      font, NSFontAttributeName,
                                      paragraphStyle, NSParagraphStyleAttributeName,
                                      nil] autorelease];
  
  NSRect labelRect = [badge boundingRectWithSize:NSMakeSize(64.0, 20.0)
                                         options:drawingOptions
                                      attributes:attributes];
  
  labelRect.origin = frame.origin;
  
  static CGFloat minBadgeWidth = 20.0;
  static CGFloat cornerRadius = 8.0;
  static CGFloat padding = 4.0;
  
  CGFloat badgeWidth = labelRect.size.width + padding*2;
  
  if (badgeWidth < minBadgeWidth) badgeWidth = minBadgeWidth;
  
  labelRect.origin.x += (frame.size.width - badgeWidth) + round((badgeWidth - labelRect.size.width)/2);
  
  NSRect badgeRect = labelRect;
  badgeRect.size.width = badgeWidth;
  badgeRect.origin.x = frame.origin.x + (frame.size.width - badgeRect.size.width);
  
  
  NSColor* fillColor = nil;
  if ([self isHighlighted])
  {
    fillColor = [NSColor whiteColor];
  }
  else
  {
    if (self.isForeground)
    {
      fillColor = [NSColor colorWithCalibratedHue:217.0/360.0 saturation:0.27 brightness:0.79 alpha:1.0];
    }
    else
    {
      fillColor = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:0.67 alpha:1.0];
    }
  }
  
  CGContextRef context = CGContextCurrentContext();
  CGContextSaveGState(context);
  CGContextAddRoundRect(context, NSRectToCGRect(badgeRect), cornerRadius);
  CGColorRef fillColorRef = CGColorCreateFromNSColor(fillColor);
  [fillColor set];
  CGColorRelease(fillColorRef);
  CGContextFillPath(context);
  CGContextRestoreGState(context);
  
 // [NSBezierPath fillRect:badgeRect];
  [badge drawInRect:labelRect withAttributes:attributes];
  
  return badgeRect;
}










- (void) drawTitleInFrame:(NSRect)frame
{
  BOOL isHighlighted = [self isHighlighted];
  
  NSColor* textColor = [NSColor blackColor];
  
  if (isHighlighted)
  {
    textColor = [NSColor alternateSelectedControlTextColor];
  }
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  static CGFloat fontSize = 11.0; // 12.0
  NSFont* font = isHighlighted ? [NSFont boldSystemFontOfSize:fontSize] : [NSFont systemFontOfSize:fontSize];
  
	NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           textColor, NSForegroundColorAttributeName,
                                           font, NSFontAttributeName,
                                           paragraphStyle, NSParagraphStyleAttributeName,
                                           nil] autorelease];
  
  if (isHighlighted)
  {
    NSShadow* s = [[[NSShadow alloc] init] autorelease];
    [s setShadowOffset:NSMakeSize(0, -1)];
    [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
    [attributes setObject:s forKey:NSShadowAttributeName];
  }
  
  static CGFloat offset = 0; //-2;
  //if ([self isFlipped]) offset = -offset;
  frame.origin.y += offset;
  frame.size.height += fabs(offset);
  
 // NSString* title = [[self repositoryController] titleForSourceList];
  NSString* title = [[self repositoryController] nameForSourceList];
  [title drawInRect:frame withAttributes:attributes];
}







- (void) drawSubtitleInFrame:(NSRect)frame
{
  return;
  NSColor* textColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
  
  if ([self isHighlighted])
  {
    textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.5];
  }
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  NSFont* font = [NSFont systemFontOfSize:10.0];
  
	NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      textColor, NSForegroundColorAttributeName,
                                      font, NSFontAttributeName,
                                      paragraphStyle, NSParagraphStyleAttributeName,
                                      nil] autorelease];
  
  if ([self isHighlighted])
  {
    NSShadow* s = [[[NSShadow alloc] init] autorelease];
    [s setShadowOffset:NSMakeSize(0, 1)];
    [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    [attributes setObject:s forKey:NSShadowAttributeName];
  }
  
  [[[self repositoryController] subtitleForSourceList] drawInRect:frame withAttributes:attributes];  
}



@end
