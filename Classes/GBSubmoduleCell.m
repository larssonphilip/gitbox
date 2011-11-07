#import "GBSubmoduleCell.h"
#import "GBSubmodule.h"
#import "GBSidebarItem.h"
#import "GBRepositoryController.h"

@interface GBSubmoduleCell ()
@property(nonatomic, retain, readonly) GBSubmodule* submodule;
- (GBRepositoryController*) repositoryController;
- (NSRect) drawDownloadButtonAndReturnRemainingRect:(NSRect)rect;
@end

static NSString* const kGBSubmoduleCellButton = @"GBSubmoduleCellButton";

@implementation GBSubmoduleCell


#pragma mark GBSidebarCell

- (NSImage*) image
{
	if ([[self submodule] status] == GBSubmoduleStatusNotCloned)
	{
		return [NSImage imageNamed:@"GBSidebarSubmoduleMissingIcon.png"];
	}
	return [NSImage imageNamed:NSImageNameFolder];
	return [NSImage imageNamed:@"GBSidebarSubmoduleIcon.png"];
}

- (NSRect) drawExtraFeaturesAndReturnRemainingRect:(NSRect)rect
{
	if (![self.submodule isCloned] && ![self.sidebarItem visibleSpinning] && [self.sidebarItem isExpanded])
	{
		return [self drawDownloadButtonAndReturnRemainingRect:rect];
	}
	else
	{
		[self.sidebarItem setView:nil forKey:kGBSubmoduleCellButton];
	}
	return [super drawExtraFeaturesAndReturnRemainingRect:rect];
}



#pragma mark Private


- (NSRect) drawDownloadButtonAndReturnRemainingRect:(NSRect)rect
{
	NSButton* button = (NSButton*)[self.sidebarItem viewForKey:kGBSubmoduleCellButton];
	if (!button)
	{
		// TODO: adjust the frame to the contained text
		button = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50.0, 13.0)] autorelease];
		
		// TODO: support also "Update" button which pull and checks out updated HEAD
		[button setTitle:NSLocalizedString(@"Download", @"")];
		
		[button setBezelStyle:NSRoundRectBezelStyle];
		[[button cell] setControlSize:NSMiniControlSize];
		[[button cell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:[[button cell] controlSize]]]];
		[self.sidebarItem setView:button forKey:kGBSubmoduleCellButton];
		
		[button setAction:@selector(download:)];
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
	return (GBSubmodule*)[self.sidebarItem object];
}

- (GBRepositoryController*) repositoryController
{
	return self.submodule.repositoryController;
}

@end
