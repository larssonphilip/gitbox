#import "GBCommit.h"
#import "GBMergeCommitCell.h"

@implementation GBMergeCommitCell


+ (CGFloat) cellHeight
{
  return 19.0;
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
                                             [NSFont systemFontOfSize:11.0], NSFontAttributeName,
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
  
  CGFloat titleWidthRatio = 0.34;
  CGFloat dateWidthRatio = 0.50; // of the rest
  CGFloat padding = 5.0;
  CGFloat titleMessagePadding = 1.0;
  CGFloat verticalShiftForSmallText = 2.0;
  CGFloat x0 = innerRect.origin.x;
  CGFloat y0 = innerRect.origin.y;
  
  // Calculate layout
  
  CGFloat maxTitleWidth = innerRect.size.width*titleWidthRatio;
  titleSize.width = (titleSize.width > maxTitleWidth ? maxTitleWidth : titleSize.width);

  CGFloat maxDateWidth = (innerRect.size.width - titleSize.width)*dateWidthRatio;
  dateSize.width = (dateSize.width > maxDateWidth ? maxDateWidth : dateSize.width);
  
  NSRect dateRect = NSMakeRect(x0 + innerRect.size.width - dateSize.width,
                               y0 + verticalShiftForSmallText,
                               dateSize.width,
                               dateSize.height);
  
  NSRect titleRect = NSMakeRect(x0,
                                y0,
                                titleSize.width,
                                titleSize.height);
  
  NSRect messageRect = NSMakeRect(x0 + titleSize.width + padding,
                                  y0 + verticalShiftForSmallText,
                                  innerRect.size.width - (titleSize.width + padding) - (dateSize.width + padding),
                                  innerRect.size.height);
  
  // draw
  
  [date drawInRect:dateRect withAttributes:dateAttributes];
  [title drawInRect:titleRect withAttributes:titleAttributes];
  [message drawInRect:messageRect withAttributes:messageAttributes];
  
}

@end
