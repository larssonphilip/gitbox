#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"
#import "CGContext+OACGContextHelpers.h"
#import "GBLightScroller.h"
#import "GBSidebarOutlineView.h"


@interface GBRepositoryCell ()
- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)frame;
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
  // Displaying spinner or badge
  
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
    [self.outlineView addSubview:spinner];
  }
  else
  {
    [spinner removeFromSuperview];
    spinner = nil;
  }
  
  
  if (spinner)
  {
    static CGFloat leftPadding = 2.0;
    static CGFloat rightPadding = 2.0;
    static CGFloat yOffset = -1.0;
    NSRect spinnerFrame = [spinner frame];
    spinnerFrame.origin.x = rect.origin.x + (rect.size.width - spinnerFrame.size.width - rightPadding);
    spinnerFrame.origin.y = rect.origin.y + yOffset;
    [spinner setFrame:spinnerFrame];
    
    rect.size.width = spinnerFrame.origin.x - rect.origin.x - leftPadding;
  }
  else
  {
    static CGFloat leftPadding = 2.0;
    NSString* badgeLabel = [[self repositoryController] badgeLabel];
    if (badgeLabel && [badgeLabel length] > 0 && !self.isDragged)
    {
      NSRect badgeFrame = [self drawBadge:badgeLabel inRect:rect];
      rect.size.width = badgeFrame.origin.x - rect.origin.x - leftPadding;
    }
  }
  
  return rect;
}







- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)frame
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


#pragma mark Private


- (GBBaseRepositoryController*) repositoryController
{
  return (GBBaseRepositoryController*)[self representedObject];
}

@end
