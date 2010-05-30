#import "GBCommit.h"
#import "GBCommitCell.h"

@implementation GBCommitCell

- (GBCommit*) commit
{
  return [self representedObject];
}

+ (CGFloat) cellHeight
{
  return 38.0;
}

- (void) drawContentInFrame:(NSRect)cellFrame
{
  
  NSRect innerRect = NSInsetRect(cellFrame, 6.0, 2.0);
  
  GBCommit* object = [self commit];
  
  NSString* title = object.authorName;
  NSString* date = @"";
  NSString* message = object.message;
  
  if (object.date)
  {
    NSDateFormatter* dateFormatter = [[NSDateFormatter new] autorelease];
    if ([object.date timeIntervalSinceNow] > -12*3600)
    {
      [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    }
    else
    {
      [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    date = [dateFormatter stringFromDate:object.date];
  }
  
  // Prepare colors and styles
  
  NSColor* textColor = [NSColor textColor];
  NSColor* dateColor = [NSColor colorWithCalibratedRed:51/255.0 green:102/255.0 blue:204/255.0 alpha:1.0];
  
  if ([self isHighlighted])
  {
    textColor = [NSColor alternateSelectedControlTextColor];
    dateColor = textColor;
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
  CGFloat verticalShiftForDate = 2.0;
  CGFloat x0 = innerRect.origin.x;
  CGFloat y0 = innerRect.origin.y;
  
  // Calculate layout
  
  CGFloat maxDateWidth = innerRect.size.width*dateWidthRatio;
  dateSize.width = (dateSize.width > maxDateWidth ? maxDateWidth : dateSize.width);
  
  NSRect dateRect = NSMakeRect(x0 + innerRect.size.width - dateSize.width,
                               y0 + verticalShiftForDate,
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
  
  [date drawInRect:dateRect withAttributes:dateAttributes];
  [title drawInRect:titleRect withAttributes:titleAttributes];
  [message drawInRect:messageRect withAttributes:messageAttributes];
  
}

//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)theControlView
- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{  
  NSColor* backgroundColor = [NSColor controlBackgroundColor];
  
  if ([self isHighlighted])
  {
    backgroundColor = [NSColor alternateSelectedControlColor];
  }
  
  [backgroundColor set];
  NSRectFill(cellFrame);

  [self drawContentInFrame:cellFrame];
}


- (id) copyWithZone:(NSZone *)zone
{
  GBCommitCell* c = [super copyWithZone:zone];
  c.representedObject = self.representedObject;
  return c;
}



@end
