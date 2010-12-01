#import "GBRepositoryCell.h"
#import "GBBaseRepositoryController.h"

@interface GBRepositoryCell ()
- (void) drawTitleInFrame:(NSRect)frame;
- (void) drawSubtitleInFrame:(NSRect)frame;
@end

@implementation GBRepositoryCell

@synthesize isFocused;

#define kIconImageWidth		16.0



+ (CGFloat) cellHeight
{
  return 35.0;
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
  NSWindow* window = [theControlView window];
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);

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
  
  
  
  
  // Title & subtitle
  
  
  NSString* badgeLabel = [[self repositoryController] badgeLabel];
  if (badgeLabel && [badgeLabel length] > 0)
  {
    NSRect badgeFrame;
    
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

- (void) drawTitleInFrame:(NSRect)frame
{
  NSColor* textColor = [NSColor blackColor];
  
  if ([self isHighlighted])
  {
    textColor = [NSColor alternateSelectedControlTextColor];
  }
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  NSFont* font = [NSFont systemFontOfSize:11.0];
  
	NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           textColor, NSForegroundColorAttributeName,
                                           font, NSFontAttributeName,
                                           paragraphStyle, NSParagraphStyleAttributeName,
                                           nil] autorelease];
  
  if ([self isHighlighted])
  {
    NSShadow* s = [[[NSShadow alloc] init] autorelease];
    [s setShadowOffset:NSMakeSize(0, 1)];
    [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.2]];
    [attributes setObject:s forKey:NSShadowAttributeName];
  }
  
  [[[self repositoryController] titleForSourceList] drawInRect:frame withAttributes:attributes];
}

- (void) drawSubtitleInFrame:(NSRect)frame
{
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
