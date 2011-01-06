#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"
#import "CGContext+OACGContextHelpers.h"
#import "GBLightScroller.h"


#define kIconImageWidth		16.0


@interface GBRepositoryCell ()
- (NSRect) drawBadge:(NSString*)badge inTitleFrame:(NSRect)frame;
- (void) drawTitleInFrame:(NSRect)frame;
@end

@implementation GBRepositoryCell

@synthesize isForeground;
@synthesize isFocused;

- (void) dealloc
{
  [super dealloc];
}

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
  
  
  // Spinner
  
  NSProgressIndicator* spinner = [self repositoryController].sidebarSpinner;
  if ([self repositoryController].isSpinning)
  {
    if (!spinner)
    {
      spinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)] autorelease];
      [spinner setStyle:NSProgressIndicatorSpinningStyle];
      [spinner setIndeterminate:YES];
      [spinner startAnimation:nil];
      [spinner setControlSize:NSSmallControlSize];
      [self repositoryController].sidebarSpinner = spinner;
    }
    [theControlView addSubview:spinner];
  }
  else
  {
    [spinner removeFromSuperview];
    spinner = nil;
  }
  
  
  // Title & subtitle
  
  if (spinner)
  {
    static CGFloat leftPadding = 2.0;
    static CGFloat rightPadding = 2.0;
    static CGFloat yOffset = 0.0;
    NSRect spinnerFrame = [spinner frame];
    spinnerFrame.origin.x = textualFrame.origin.x + (textualFrame.size.width - spinnerFrame.size.width - rightPadding);
    spinnerFrame.origin.y = textualFrame.origin.y + yOffset;
    [spinner setFrame:spinnerFrame];
    
    textualFrame.size.width = spinnerFrame.origin.x - textualFrame.origin.x - leftPadding;
  }
  else
  {
    static CGFloat leftPadding = 2.0;
    NSString* badgeLabel = [[self repositoryController] badgeLabel];
    if (badgeLabel && [badgeLabel length] > 0)
    {
      NSRect badgeFrame = [self drawBadge:badgeLabel inTitleFrame:textualFrame];
      textualFrame.size.width = badgeFrame.origin.x - textualFrame.origin.x - leftPadding;
    }
  }
    
  NSRect titleFrame;
  NSRect subtitleFrame;
  
  NSDivideRect(textualFrame, &titleFrame, &subtitleFrame, 14.0, NSMinYEdge);

//  if ([self repositoryController].isSpinning)
//  {
//    [[NSColor blueColor] set];
//    [NSBezierPath fillRect:titleFrame];    
//  }
//  [[NSColor redColor] set];
//  [NSBezierPath fillRect:subtitleFrame];
  
  [self drawTitleInFrame:titleFrame];

  // Do not call super because we completely override text rendering.
  //[super drawInteriorWithFrame:textualFrame inView:theControlView];
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






@end
