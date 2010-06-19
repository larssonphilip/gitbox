#import "GBStageCell.h"
#import "GBStage.h"
@implementation GBStageCell

- (void) drawContentInFrame:(NSRect)cellFrame
{
  GBStage* stage = (GBStage*)[self commit];

  NSString* title = stage.message;
    
  // Prepare colors and styles
  
  NSColor* textColor = [NSColor textColor];
  
  if ([self isHighlighted] && self.isKeyCell)
  {
    textColor = [NSColor alternateSelectedControlTextColor];
  }
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  NSFont* font = nil;
  if ([stage isDirty])
  {
    font = [NSFont boldSystemFontOfSize:12.0];
  }
  else
  {
    font = [NSFont systemFontOfSize:12.0];
  }

	NSMutableDictionary* titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           textColor, NSForegroundColorAttributeName,
                                           font, NSFontAttributeName,
                                           paragraphStyle, NSParagraphStyleAttributeName,
                                           nil] autorelease];
  
  
  // Calculate heights
  NSRect innerRect = NSInsetRect(cellFrame, 19.0, 1.0);
  NSSize titleSize   = [title sizeWithAttributes:titleAttributes];
      
  // Calculate layout
  
  CGFloat x0 = innerRect.origin.x;
  CGFloat y0 = innerRect.origin.y;

  NSRect titleRect = NSMakeRect(x0,
                                y0 + cellFrame.size.height*0.5 - titleSize.height*0.5 - 1.0,
                                innerRect.size.width, 
                                titleSize.height);
    
  // draw
  
  [title drawInRect:titleRect withAttributes:titleAttributes];
  
}


@end
