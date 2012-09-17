#import "GBSidebarCell.h"
#import "GBSidebarItem.h"
#import "GBSidebarOutlineView.h"
#import "YRKSpinningProgressIndicator.h"
#import "CGContext+OACGContextHelpers.h"

#define kGBSidebarCellIconWidth 16.0
#define	kGBSidebarCellSpinnerKey @"GBSidebarCellSpinnerKey"

@interface GBSidebarCell ()
- (NSRect) drawIconAndReturnRemainingRect:(NSRect)rect;
@end

@implementation GBSidebarCell

@synthesize sidebarItem;
@synthesize outlineView;
@synthesize isForeground;
@synthesize isFocused;
@synthesize isDragged;

+ (CGFloat) cellHeight
{
	return 20.0;
}

- (void) setupCell
{
	[self setSelectable:YES];
	[self setEditable:YES];
	[self setUsesSingleLineMode:YES];
	[self setSendsActionOnEndEditing:YES];
	[self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[self setLineBreakMode:NSLineBreakByTruncatingTail];
}

- (id)initTextCell:(NSString*)string
{
	if ((self = [super initTextCell:string])) [self setupCell];
	return self;
}

- (id)initImageCell:(NSImage*)img
{
	if ((self = [super initImageCell:img])) [self setupCell];
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	if ((self = [super initWithCoder:coder])) [self setupCell];
	return self;
}

- (id) initWithItem:(GBSidebarItem*)anItem
{
	if ((self = [self initTextCell:@""]))
	{
		self.sidebarItem = anItem;
	}
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	GBSidebarCell* cell = [[[self class] alloc] initWithItem:self.sidebarItem];
	
	[cell setStringValue:[self stringValue]]; // <- this is important to make editing work
	cell.outlineView = self.outlineView;
	cell.isForeground = self.isForeground;
	cell.isFocused = self.isFocused;
	cell.isDragged = self.isDragged;
	return cell;
}




#pragma mark Subclasses' API


- (NSImage*) image
{
	return self.sidebarItem.image;
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
	// Displaying spinner or badge
	
	NSRect rect2 = [self drawSpinnerIfNeededInRectAndReturnRemainingRect:rect];
	
	if (NSEqualRects(rect2, rect))
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
	
	NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	static CGFloat fontSize = 11.0; // 12.0
	NSFont* font = isHighlighted ? [NSFont boldSystemFontOfSize:fontSize] : [NSFont systemFontOfSize:fontSize];
	
	NSMutableDictionary* attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										textColor, NSForegroundColorAttributeName,
										font, NSFontAttributeName,
										paragraphStyle, NSParagraphStyleAttributeName,
										nil];
	
	if (isHighlighted)
	{
		NSShadow* s = [[NSShadow alloc] init];
		[s setShadowOffset:NSMakeSize(0, -1)];
		[s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
		[attributes setObject:s forKey:NSShadowAttributeName];
	}
	
	static CGFloat offset = 0; //-2;
	//if ([self isFlipped]) offset = -offset;
	rect.origin.y += offset;
	rect.size.height += fabs(offset);
	
	NSString* title = self.sidebarItem.title;
	[title drawInRect:rect withAttributes:attributes];
}





#pragma mark Drawing



- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(GBSidebarOutlineView*)theControlView
{
	if (![theControlView isKindOfClass:[GBSidebarOutlineView class]]) return;
	
	self.outlineView = theControlView;
	self.isDragged = [self.outlineView preparesImageForDragging];
	NSWindow* window = [self.outlineView window];
	self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
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



- (NSRect) drawIconAndReturnRemainingRect:(NSRect)rect
{
	NSImage* image = [self image];
	
	NSSize imageSize = NSMakeSize(kGBSidebarCellIconWidth, kGBSidebarCellIconWidth);
	[image setSize:imageSize];
	
	NSRect imageFrame;
	NSRect rect2;
	
	NSDivideRect(rect, &imageFrame, &rect2, 6 + imageSize.width, NSMinXEdge);
	
	imageFrame.origin.x += 3;
	imageFrame.size = imageSize;
	
	imageFrame.origin.y += 1;

	[image drawInRect:imageFrame
			   fromRect:NSMakeRect(0, 0, image.size.width, image.size.height)
			  operation:NSCompositeSourceOver
			   fraction:1.0
		 respectFlipped:YES
				  hints:nil];
	
	rect2.origin.x += 2;
	rect2.origin.y += 3;
	rect2.size.height -= 3;
	rect2.size.width -= 5;
	
	return rect2;
}

- (NSRect) drawCustomSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
	if ([self.sidebarItem isStopped]) return rect;
	
	if (![self.sidebarItem visibleSpinning])
	{
		[self.sidebarItem setView:nil forKey:kGBSidebarCellSpinnerKey];
		return rect;
	}
	
	YRKSpinningProgressIndicator* spinner = (YRKSpinningProgressIndicator*)[self.sidebarItem viewForKey:kGBSidebarCellSpinnerKey];
	if (!spinner)
	{
		spinner = [[YRKSpinningProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)];
		//spinner.actsAsCell = YES;
		
		[self.sidebarItem setView:spinner forKey:kGBSidebarCellSpinnerKey];
	}
	if (spinner.superview != self.outlineView)
	{
		[self.outlineView addSubview:spinner];
	}
	[spinner setHidden:NO];
	
	if (!self.isHighlighted)
	{
		if (self.isForeground)
		{
			spinner.color = [NSColor colorWithCalibratedHue:217.0/360.0 saturation:0.27 brightness:0.40 alpha:1.0];
		}
		else
		{
			spinner.color = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:0.50 alpha:1.0];
		}
	}
	else
	{
		spinner.color = [NSColor whiteColor];
	}
	
	if (!spinner) return rect;
	
	double progress = self.sidebarItem.visibleProgress;
	[spinner setIndeterminate:progress <= 1.0 || progress >= 99.9];
	if (!spinner.isIndeterminate)
	{
		[spinner setDoubleValue:MAX(MIN(progress, 100.0), 6.0)];
	}
	
	[spinner startAnimation:nil];
	
	static CGFloat leftPadding = 2.0;
	static CGFloat rightPadding = 2.0;
	static CGFloat yOffset = -1.0;
	NSRect spinnerFrame = spinner.frame;
	spinnerFrame.origin.x = rect.origin.x + (rect.size.width - spinnerFrame.size.width - rightPadding);
	spinnerFrame.origin.y = rect.origin.y + yOffset;
	[spinner setFrame:spinnerFrame];
	
	rect.size.width = spinnerFrame.origin.x - rect.origin.x - leftPadding;
	
	// Drop a backdrop behind the spinner for selected item
	if (self.isHighlighted)
	{
		NSRect imageRect = NSRectFromCGRect(CGRectInset(NSRectToCGRect(spinnerFrame), -1.0, -1.0));
		
		NSImage* image = [NSImage imageNamed:@"GBSidebarCellSpinnerBackdrop.png"];
		[image setSize:imageRect.size];
		[image drawInRect:imageRect
				   fromRect:NSMakeRect(0, 0, image.size.width, image.size.height)
				  operation:NSCompositeSourceOver
				   fraction:1.0
			 respectFlipped:YES
					  hints:nil];
	}
	
	return rect;
}

- (NSRect) drawCocoaSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
	if ([self.sidebarItem isStopped]) return rect;
	
	if (![self.sidebarItem visibleSpinning])
	{
		[self.sidebarItem setView:nil forKey:kGBSidebarCellSpinnerKey];
		return rect;
	}
	
	NSProgressIndicator* spinner = (NSProgressIndicator*)[self.sidebarItem viewForKey:kGBSidebarCellSpinnerKey];
	if (!spinner)
	{
		spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)];
		[spinner setStyle:NSProgressIndicatorSpinningStyle];
		[spinner setControlSize:NSSmallControlSize];
		[self.sidebarItem setView:spinner forKey:kGBSidebarCellSpinnerKey];
	}
	
	if (!spinner) return rect;
	
	double progress = [self.sidebarItem visibleProgress];
	BOOL newFlag = progress <= 0.1 || progress >= 99.9;
	BOOL changedMode = spinner.isIndeterminate != newFlag;
	[spinner setIndeterminate:newFlag];
	[spinner setDoubleValue:progress];
	if (changedMode) [spinner stopAnimation:nil];
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

- (NSRect) drawSpinnerIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
	return [self drawCustomSpinnerIfNeededInRectAndReturnRemainingRect:rect];
}



- (NSRect) drawBadgeIfNeededInRectAndReturnRemainingRect:(NSRect)rect
{
	static CGFloat leftPadding = 2.0;
	NSInteger badgeValue = [self.sidebarItem visibleBadgeInteger];
	
	if (badgeValue > 0)
	{
		NSString* badgeLabel = [NSString stringWithFormat:@"%lu", badgeValue];
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
	
	NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
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
	
	NSMutableDictionary* attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										textColor, NSForegroundColorAttributeName,
										font, NSFontAttributeName,
										paragraphStyle, NSParagraphStyleAttributeName,
										nil];
	
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
