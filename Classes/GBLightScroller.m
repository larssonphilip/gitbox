#import "GBLightScroller.h"

#import "CGContext+OACGContextHelpers.h"

static const CGFloat GBLightScrollerMaxAlpha = 0.4;

BOOL GBLightScrollerIsModernOS()
{
	return !!NSClassFromString(@"NSPopover"); // class is nil on Snow Leopard.
}

@interface GBLightScroller ()
@property(nonatomic, assign) CGRect lastKnobRect;
@property(nonatomic, assign) CGFloat lastKnobAlpha;
@property(nonatomic, assign) BOOL shouldFadeKnob;
@property(nonatomic, assign) BOOL mouseIsOverScroller;
@end

@implementation GBLightScroller

@synthesize lastKnobRect;
@synthesize lastKnobAlpha;
@synthesize shouldFadeKnob;
@synthesize mouseIsOverScroller;

+ (BOOL) isModernScroller
{
	return GBLightScrollerIsModernOS();
}

+ (CGFloat) width
{
	return GBLightScrollerIsModernOS() ? 0.0 : 9.0; // 0.0 for modern scroller means avoiding additional content offsets
}

+ (BOOL)isCompatibleWithOverlayScrollers
{
	return self == [GBLightScroller class];
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]))
	{
		self.lastKnobRect = CGRectMake(-1, -1, 0, 0);
		self.lastKnobAlpha = GBLightScrollerMaxAlpha;
		self.shouldFadeKnob = NO;
		self.mouseIsOverScroller = NO;
	}
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL) isOpaque
{
	return GBLightScrollerIsModernOS() ? [super isOpaque] : NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (GBLightScrollerIsModernOS())
	{
		[super drawRect:dirtyRect];
	}
	else
	{
		[self drawKnob];
	}
}

//- (void) gbclearRect:(NSRect)rect
//{
//	//[[NSColor colorWithDeviceWhite:0.5 alpha:0.5] setFill];
//	//NSRectFillListUsingOperation(&rect, 1, NSCompositeCopy);  
//	//NSRectFill(rect);
//}

//- (void) drawArrow:(NSScrollerArrow)arrow highlightPart:(int)flag
//{
//	NSRect rect =  [self rectForPart:(arrow == NSScrollerIncrementArrow ? NSScrollerIncrementLine : NSScrollerDecrementLine)];
//	[self gbclearRect:rect];
//}

- (void) drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
	if (GBLightScrollerIsModernOS()) [super drawKnobSlotInRect:rect highlight:highlight];
}

- (void) setNeedsDisplayKnob
{
	[self setNeedsDisplay:YES];
}

- (void) setNeedsFadeKnob
{
	self.shouldFadeKnob = YES;
	[self setNeedsDisplayKnob];
}

//- (void)mouseMoved:(NSEvent*)theEvent
//{
//  NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//  NSLog(@"bounds = %@ point = %@", NSStringFromRect(self.bounds), NSStringFromPoint(point));
//  if (CGRectContainsPoint(self.bounds, point))
//  {
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setNeedsDisplayKnob) object:nil];
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setNeedsFadeKnob) object:nil];
//    self.mouseIsOverScroller = YES;
//  }
//  else
//  {
//    self.mouseIsOverScroller = NO;
//    [self setNeedsDisplayKnob];
//  }
//  [super mouseMoved:theEvent];
//}

- (void) drawKnob
{
	if (GBLightScrollerIsModernOS())
	{
		[super drawKnob];
		return;
	}
	
	CGRect rect = NSRectToCGRect([self rectForPart:NSScrollerKnob]);
	
	CGFloat alpha = self.lastKnobAlpha;
	
	CGFloat topY = 3.0;
	
	if ((CGRectEqualToRect(rect, self.lastKnobRect) || (rect.origin.y <= topY && self.lastKnobRect.origin.y <= topY)) && !self.mouseIsOverScroller)
	{
		if (self.shouldFadeKnob)
		{
			alpha = alpha*0.8 - 0.05;
			if (alpha < 0.05) alpha = 0.0;
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			if (alpha > 0)
			{
				[self performSelector:@selector(setNeedsDisplayKnob) withObject:nil afterDelay:0.03];
			}
			else
			{
				self.shouldFadeKnob = NO;
			}
		}
	}
	else
	{
		self.shouldFadeKnob = NO;
		alpha = GBLightScrollerMaxAlpha;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setNeedsDisplayKnob) object:nil];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setNeedsFadeKnob) object:nil];
	}
	self.lastKnobRect = rect;
	if (!self.shouldFadeKnob)
	{
		[self performSelector:@selector(setNeedsFadeKnob) withObject:nil afterDelay:0.5];
	}
	
	//  CGFloat alphaDistanceMultiplier = 1.0; // 1.0 if farther than 50px, 
	//  CGFloat threshold = fminf(rect.size.height/2.0, 30.0);
	//  if (rect.origin.y < threshold)
	//  {
	//    alphaDistanceMultiplier = (rect.origin.y - 3.0)/(threshold);
	//    if (alphaDistanceMultiplier < 0) alphaDistanceMultiplier = 0;
	//    CGFloat limit = 0.0;
	//    alphaDistanceMultiplier = limit + (1-limit)*alphaDistanceMultiplier;
	//  }
	//
	//  alpha *= alphaDistanceMultiplier;
	
	rect = CGRectInset(rect, 0, 0.5);
	CGFloat width = 7.0;
	rect.origin.x = rect.origin.x + (rect.size.width - width - 1.0) - 0.5;
	rect.size.width = width;
	
	if (!([[self window] isMainWindow] && [[self window] isKeyWindow])) // inactive window
	{
		alpha *= 0.6;
	}
	
	self.lastKnobAlpha = alpha;
	
	
	CGFloat radius = 3.5;
	
	CGContextRef context = CGContextCurrentContext();
	CGContextSaveGState(context);
	// transparency layer is used because we play with blend mode for stroke (see below)
	CGContextBeginTransparencyLayerWithRect(context, rect, NULL);  
	CGContextAddRoundRect(context, rect, radius);
	CGContextClip(context);
	
	CGColorRef color1 = CGColorCreateGenericRGB(0.0, 0.0, 0.0, alpha*0.7);
	CGColorRef color2 = CGColorCreateGenericRGB(0.0, 0.0, 0.0, alpha);
	CGColorRef colorsList[] = { color1, color2 };
	CFArrayRef colors = CFArrayCreate(NULL, (const void**)colorsList, sizeof(colorsList) / sizeof(CGColorRef), &kCFTypeArrayCallBacks);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, NULL);
	
	CGContextDrawLinearGradient(context,
								gradient,
								rect.origin,
								CGPointMake(rect.origin.x + rect.size.width, rect.origin.y), 
								0);
	
	CFRelease(colorSpace);
	CFRelease(colors);
	CFRelease(color1);
	CFRelease(color2);
	CFRelease(gradient);
	
	CGContextRestoreGState(context);
	
	CGContextAddRoundRect(context, rect, radius);
	
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, alpha*0.3);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetLineJoin(context, kCGLineJoinRound);
	CGContextSetLineCap(context, kCGLineCapButt);
	
	// Stroke is drawn over the fill color. To discard fill color below the stroke, we use "copy" blending mode.
	CGContextSetBlendMode(context, kCGBlendModeCopy); 
	
	CGContextDrawPath(context, kCGPathStroke);
	CGContextEndTransparencyLayer(context);
}

@end
