#import "GBCommit.h"
#import "GBCommitCell.h"

@implementation GBCommitCell

- (GBCommit*) commit
{
  return [self representedObject];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{  
  NSRect innerRect = NSInsetRect(cellFrame, 5.0, 1.0);
  
  GBCommit* object = [self commit];
  
  NSString* title = object.authorName;
  NSString* date = @"";
  NSString* message = object.message;
  
  if (object.date)
  {
    NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"H:mm MMMM d, y"];
    date = [dateFormatter stringFromDate:object.date];
  }
  
  // Prepare colors and styles
  
  NSColor* textColor = [NSColor textColor];
  NSColor* dateColor = [NSColor blueColor];
  NSColor* backgroundColor = [NSColor controlBackgroundColor];
  
  if ([self isHighlighted])
  {
    textColor = [NSColor alternateSelectedControlTextColor];
    dateColor = textColor;
    backgroundColor = [NSColor alternateSelectedControlColor];
  }
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  
	NSMutableDictionary* titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                                             paragraphStyle, NSParagraphStyleAttributeName,
                                             nil] autorelease];
  
  NSMutableDictionary* dateAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                            dateColor, NSForegroundColorAttributeName,
                                            [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                            paragraphStyle, NSParagraphStyleAttributeName,
                                            nil] autorelease];

  NSMutableDictionary* messageAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                          textColor, NSForegroundColorAttributeName,
                                          [NSFont systemFontOfSize:12.0], NSFontAttributeName,
                                          paragraphStyle, NSParagraphStyleAttributeName,
                                          nil] autorelease];
  
  // Calculate heights
  
  NSSize titleSize   = [title sizeWithAttributes:titleAttributes];
  NSSize dateSize    = [date sizeWithAttributes:dateAttributes];
  NSSize messageSize = [message sizeWithAttributes:messageAttributes];
  
  
  
  /*
     +-----------------+ +----------+
     | title           | | date     |
     +-----------------+ +----------+
     +------------------------------+
     | message                      |
     +------------------------------+
   (origin.x;origin.y)
  */
  
  // Layout constants
  
  CGFloat dateWidthRatio = 0.5; // 50% of the width
  CGFloat titleDatePadding = 3.0;
  CGFloat titleMessagePadding = 1.0;
  
  CGFloat x0 = innerRect.origin.x;
  CGFloat y0 = innerRect.origin.y;
  
  // Calculate layout
  
  CGFloat maxDateWidth = innerRect.size.width*dateWidthRatio;
  dateSize.width = (dateSize.width > maxDateWidth ? maxDateWidth : dateSize.width);
  
  NSRect dateRect = NSMakeRect(x0 + innerRect.size.width - dateSize.width,
                               y0,
                               dateSize.width,
                               dateSize.height);
  
  NSRect titleRect = NSMakeRect(x0,
                                y0,
                                innerRect.size.width - dateSize.width - titleDatePadding, 
                                titleSize.height);

  NSRect messageRect = NSMakeRect(x0, 
                                  y0 + titleSize.height + titleMessagePadding, 
                                  innerRect.size.width,
                                  innerRect.size.height - titleSize.height - titleMessagePadding);
  
  // draw
  
  [backgroundColor set];
  NSRectFill(cellFrame);
  
  [date drawInRect:dateRect withAttributes:dateAttributes];
  [title drawInRect:titleRect withAttributes:titleAttributes];
  [message drawInRect:messageRect withAttributes:messageAttributes];
  
}





@end
