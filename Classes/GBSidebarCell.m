#import "GBSidebarCell.h"
#import "GBSidebarItem.h"
#import "GBSidebarOutlineView.h"
#import "GBLightScroller.h"
#import "CGContext+OACGContextHelpers.h"

#define kGBSidebarCellIconWidth 16.0

@interface GBSidebarCell ()
- (id<GBSidebarItem>) sidebarItem;
- (NSRect) drawIconAndReturnRemainingRect:(NSRect)rect;
@end

@implementation GBSidebarCell

@synthesize isForeground;
@synthesize isFocused;
@synthesize isDragged;
@synthesize outlineView;

+ (CGFloat) cellHeight
{
  return 20.0;
}



#pragma mark Subclasses' API


- (NSImage*) icon
{
  return nil;
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
  // Displaying spinner or badge
  
  NSRect rect2 = [self drawSpinnerIfNeededInRectAndReturnRemainingRect:rect];
  
  if (rect2.size.width == rect.size.width && rect2.size.height == rect.size.height)
  {
    rect2 = [self drawBadgeIfNeededInRectAndReturnRemainingRect:rect];
  }
  return rect2;
}



- (void) drawTextInRect:(NSRect)rect
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
  rect.origin.y += offset;
  rect.size.height += fabs(offset);
  
  NSString* title = [[self sidebarItem] nameInSidebar];
  [title drawInRect:rect withAttributes:attributes];
}





#pragma mark Drawing



- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(GBSidebarOutlineView*)theControlView
{
  self.outlineView = theControlView;
  self.isDragged = [self.outlineView preparesImageForDragging];
  NSWindow* window = [self.outlineView window];
  self.isFocused = ([window firstResponder] && [window firstResponder] == self.outlineView && 
                    [window isMainWindow] && [window isKeyWindow]);
  self.isForeground = [window isMainWindow];

  // Debug:
  //[[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:1.0 alpha:0.3] set];
  //[NSBezierPath fillRect:cellFrame];
  
  // 1. Draw the icon
  NSRect rect = [self drawIconAndReturnRemainingRect:cellFrame];
  
  // 2. Draw extra features on the left: badge, spinner, button, sharing icon etc.
  rect = [self drawExtraFeaturesAndReturnRemainingRect:rect];
  
  // 3. Fill remaining space with text
  [self drawTextInRect:rect];
}





#pragma mark AppKit


- (id)init
{
  if ((self = [super init]))
  {
    [self setSelectable:YES];
    [self setUsesSingleLineMode:YES];
    [self setSendsActionOnEndEditing:YES];
    [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
  }
  return self;
}

- (id) copyWithZone:(NSZone *)zone
{
  GBSidebarCell* cell = [super copyWithZone:zone];
  [cell setRepresentedObject:[self representedObject]];
  return cell;
}


- (BOOL) isEditable
{
  return [[self sidebarItem] isEditableInSidebar];
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
  textObj = [super setUpFieldEditorAttributes:textObj];
  return textObj;
}

- (NSRect) editorFrameForSuggestedRect:(NSRect)aRect
{
  NSRect textFrame, imageFrame;
  NSDivideRect (aRect, &imageFrame, &textFrame, 6 + kGBSidebarCellIconWidth, NSMinXEdge);
  textFrame.origin.y += 3.0;
  textFrame.size.height -= 6;
  return textFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
  [super editWithFrame:[self editorFrameForSuggestedRect:aRect] inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
  [super selectWithFrame:[self editorFrameForSuggestedRect:aRect] inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}




#pragma mark Private


- (id<GBSidebarItem>) sidebarItem
{
  return (id<GBSidebarItem>)[self representedObject];
}

- (NSRect) drawIconAndReturnRemainingRect:(NSRect)rect
{
  NSImage* image = [self icon];
  
  NSSize imageSize = NSMakeSize(kGBSidebarCellIconWidth, kGBSidebarCellIconWidth);
  [image setSize:imageSize];
  
  NSRect imageFrame;
  NSRect rect2;
  
  NSDivideRect(rect, &imageFrame, &rect2, 6 + imageSize.width, NSMinXEdge);
  
  imageFrame.origin.x += 3;
  imageFrame.size = imageSize;
  
  if ([self.outlineView isFlipped])
  {
    imageFrame.origin.y += imageFrame.size.height + 2;
  }
  else
  {
    imageFrame.origin.y += 1;
  }
  [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
  
  rect2.origin.x += 2;
  rect2.origin.y += 3;
  rect2.size.height -= 3;
  rect2.size.width -= [GBLightScroller width] + 1; // make some room for scrollbar
  
  return rect2;
}


- (NSRect) drawSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
  NSProgressIndicator* spinner = [[self sidebarItem] sidebarSpinner];
  BOOL isSpinning = [[self sidebarItem] isSpinningInSidebar];
  if (![[self sidebarItem] isExpandedInSidebar])
  {
    isSpinning = [[self sidebarItem] isAccumulatedSpinningInSidebar];
  }
  
  if (!isSpinning)
  {
    [spinner removeFromSuperview];
    return rect;
  }
  
  if (!spinner)
  {
    spinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)] autorelease];
    [spinner setStyle:NSProgressIndicatorSpinningStyle];
    [spinner setControlSize:NSSmallControlSize];
    [[self sidebarItem] setSidebarSpinner:spinner];
    spinner = [[self sidebarItem] sidebarSpinner];
    if (!spinner) return rect;
  }
  
  [spinner setIndeterminate:YES];
  [spinner startAnimation:nil];
  [spinner setHidden:NO];
  [self.outlineView addSubview:spinner];

  static CGFloat leftPadding = 2.0;
  static CGFloat rightPadding = 2.0;
  static CGFloat yOffset = -1.0;
  NSRect spinnerFrame = [spinner frame];
  spinnerFrame.origin.x = rect.origin.x + (rect.size.width - spinnerFrame.size.width - rightPadding);
  spinnerFrame.origin.y = rect.origin.y + yOffset;
  [spinner setFrame:spinnerFrame];
  
  rect.size.width = spinnerFrame.origin.x - rect.origin.x - leftPadding;
  
  return rect;
}


- (NSRect) drawBadgeIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
  static CGFloat leftPadding = 2.0;
	NSInteger badgeValue = [[self sidebarItem] badgeValue];
	if (![[self sidebarItem] isExpandedInSidebar])
	{
		badgeValue = [[self sidebarItem] accumulatedBadgeValue];
	}
	
	if (badgeValue > 0)
	{
		NSString* badgeLabel = [NSString stringWithFormat:@"%d", badgeValue];
		if (badgeValue > 999)
		{
			badgeLabel = @"999+";
		}
		if (badgeLabel && [badgeLabel length] > 0 && !self.isDragged)
		{
			NSRect badgeFrame = [self drawBadge:badgeLabel inRect:rect];
			rect.size.width = badgeFrame.origin.x - rect.origin.x - leftPadding;
		}
	}
    
  return rect;
}


- (NSRect) drawBadge:(NSString*)badge inRect:(NSRect)rect
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
	
	labelRect.origin = rect.origin;
	
	static CGFloat minBadgeWidth = 20.0;
	static CGFloat cornerRadius = 8.0;
	static CGFloat padding = 4.0;
	
	CGFloat badgeWidth = labelRect.size.width + padding*2;
	
	if (badgeWidth < minBadgeWidth) badgeWidth = minBadgeWidth;
	
	labelRect.origin.x += (rect.size.width - badgeWidth) + round((badgeWidth - labelRect.size.width)/2);
	
	NSRect badgeRect = labelRect;
	badgeRect.size.width = badgeWidth;
	badgeRect.origin.x = rect.origin.x + (rect.size.width - badgeRect.size.width);
	
	
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
			fillColor = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:0.67 alpha:0.8];
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


@end
