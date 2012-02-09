#import "GBSubmoduleCell.h"
#import "GBSubmodule.h"
#import "GBSubmoduleController.h"
#import "GBSidebarItem.h"

@interface GBSubmoduleCell ()
@property(nonatomic, retain, readonly) GBSubmodule* submodule;
- (NSRect) drawButtonAndReturnRemainingRect:(NSRect)rect title:(NSString*)title key:(NSString*)key action:(SEL)action;
@end

static NSString* const kGBSubmoduleCellDownloadButton = @"GBSubmoduleCellDownloadButton";
static NSString* const kGBSubmoduleCellCheckoutButton = @"GBSubmoduleCellCheckoutButton";

@implementation GBSubmoduleCell


#pragma mark GBSidebarCell

- (NSImage*) image
{
	if (self.submodule.status == GBSubmoduleStatusNotCloned)
	{
		return [NSImage imageNamed:@"GBSidebarSubmoduleMissingIcon.png"];
	}
	return [NSImage imageNamed:NSImageNameFolder];
	return [NSImage imageNamed:@"GBSidebarSubmoduleIcon.png"];
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
	// Clear the spinner before we add our buttons.
	if (!self.sidebarItem.visibleSpinning)
	{
		[self drawSpinnerIfNeededInRectAndReturnRemainingRect:rect];
	}
	
	if (!self.submodule.isCloned && !self.sidebarItem.visibleSpinning && self.sidebarItem.isExpanded)
	{
		return [self drawButtonAndReturnRemainingRect:rect 
												title:NSLocalizedString(@"Download", @"GBSubmodule") 
												  key:kGBSubmoduleCellDownloadButton
											   action:@selector(startDownload:)];
	}
	else
	{
		[self.sidebarItem setView:nil forKey:kGBSubmoduleCellDownloadButton];
	}
	
	if(self.submodule.status == GBSubmoduleStatusNotUpToDate && !self.sidebarItem.visibleSpinning && self.sidebarItem.isExpanded)
	{
		return [self drawButtonAndReturnRemainingRect:rect 
												title:NSLocalizedString(@"Reset", @"GBSubmodule") 
												  key:kGBSubmoduleCellCheckoutButton
											   action:@selector(updateSubmodule:)];
	}
	else
	{
		[self.sidebarItem setView:nil forKey:kGBSubmoduleCellCheckoutButton];
	}
	return [super drawExtraFeaturesAndReturnRemainingRect:rect];
}



#pragma mark Private


- (NSRect) drawButtonAndReturnRemainingRect:(NSRect)rect title:(NSString*)title key:(NSString*)key action:(SEL)action
{
	NSButton* button = (NSButton*)[self.sidebarItem viewForKey:key];
	if (!button)
	{
		// TODO: adjust the frame to the contained text
		button = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50.0, 13.0)] autorelease];
		
		// TODO: support also "Update" button which pull and checks out updated HEAD
		[button setTitle:title];
		
		[button setBezelStyle:NSRoundRectBezelStyle];
		[[button cell] setControlSize:NSMiniControlSize];
		[[button cell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:[[button cell] controlSize]]]];
		[self.sidebarItem setView:button forKey:key];
		
		[button setAction:action];
		[button setTarget:self.sidebarItem.object];
	}
	
	if (!button) return rect;
	
	[button sizeToFit];
	[button setHidden:NO];
	[self.outlineView addSubview:button];
	
	static CGFloat leftPadding = 2.0;
	static CGFloat rightPadding = 0.0;
	static CGFloat yOffset = -2;
	NSRect buttonFrame = [button frame];
	buttonFrame.origin.x = rect.origin.x + (rect.size.width - buttonFrame.size.width - rightPadding);
	buttonFrame.origin.y = rect.origin.y + yOffset;
	[button setFrame:buttonFrame];
	
	rect.size.width = buttonFrame.origin.x - rect.origin.x - leftPadding;
	
	return rect;
}

- (GBSubmodule*) submodule
{
	GBSubmoduleController* controller = (GBSubmoduleController*)[self.sidebarItem object];
	return controller.submodule;
}

@end
