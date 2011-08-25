#import "GBLightScrollView.h"
#import "GBLightScroller.h"

@implementation GBLightScrollView

- (void) tile
{
	[super tile];
	
	NSRect scrollerFrame = [[self verticalScroller] frame];
	
	// Expand content below the scrollbar
	if (![[self verticalScroller] isHidden])
	{
		if ([GBLightScroller isModernScroller] && [self verticalScroller].scrollerStyle == NSScrollerStyleLegacy)
		{
			// do not adjust for legacy native scroller
		}
		else if (![GBLightScroller isModernScroller])
		{
			NSRect cFrame = [[self contentView] frame];
			cFrame.size.width += scrollerFrame.size.width;
			[[self contentView] setFrame:cFrame];
		}
		else
		{
			NSRect cFrame = [[self contentView] frame];
			cFrame.size.width += 1; // quick fix for the weird behaviour of nsoutlineview
			[[self contentView] setFrame:cFrame];
		}
	}
	else
	{
		NSRect cFrame = [[self contentView] frame];
		cFrame.size.width += 1; // quick fix for the weird behaviour of nsoutlineview
		[[self contentView] setFrame:cFrame];
	}
	
	if (![GBLightScroller isModernScroller])
	{
		CGFloat lightWidth = [GBLightScroller width];
		scrollerFrame.origin.x += (scrollerFrame.size.width - lightWidth);
		scrollerFrame.size.width = lightWidth;
		
		[[self verticalScroller] setFrame:scrollerFrame];
	}
}

- (void) setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
}

@end
