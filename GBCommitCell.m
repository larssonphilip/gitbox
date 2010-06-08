#import "GBCommit.h"
#import "GBCommitCell.h"

@implementation GBCommitCell

@dynamic commit;
- (GBCommit*) commit
{
  return [self representedObject];
}

+ (CGFloat) cellHeight
{
  return 38.0;
}

- (NSRect) innerRectForFrame:(NSRect)cellFrame
{
  NSRect innerRect = NSInsetRect(cellFrame, 6.0, 2.0);
  
  CGFloat offset = 13.0;
  innerRect.origin.x += offset;
  innerRect.size.width -= offset;
  
  return innerRect;
}

- (void) drawSyncStatusIconInRect:(NSRect)rect
{
  GBCommitSyncStatus st = self.commit.syncStatus;
  CGContextRef contextRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  
  if (st != GBCommitSyncStatusNormal)
  {
    if (st == GBCommitSyncStatusUnmerged)
    {
      if ([self isHighlighted])
      {
        CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.6);
      }
      else
      {
        //CGContextSetRGBFillColor(contextRef, 104.0/255.0, 162.0/255.0, 252.0/255.0, 1.0);
        CGContextSetRGBFillColor(contextRef, 100.0/255.0, 150.0/255.0, 252.0/255.0, 1.0);
      }
    }
    else
    {
      if ([self isHighlighted])
      {
        CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.99);
      }
      else
      {
        //CGContextSetRGBFillColor(contextRef, 255.0/255.0, 125.0/255.0, 0.0/255.0, 1.0);
        CGContextSetRGBFillColor(contextRef, 94.0/255.0, 220.0/255.0, 50.0/255.0, 1.0);
      }
    }
    NSPoint point = rect.origin;
    point.x -= 14.0;
    point.y += 4.0;
    
    CGRect circleRect = CGRectMake(point.x, point.y, 8.0, 8.0);
    
    CGContextFillEllipseInRect(contextRef, circleRect);
  }
}

- (void) drawContentInFrame:(NSRect)cellFrame
{  
  NSRect innerRect = [self innerRectForFrame:cellFrame];
  
  [self drawSyncStatusIconInRect:innerRect];
  
  GBCommit* object = self.commit;
  
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
  NSColor* titleColor = textColor;
  NSColor* dateColor = [NSColor colorWithCalibratedRed:107.0/255.0 green:133.0/255.0 blue:200.0/255.0 alpha:1.0];
    
  if ([self isHighlighted])
  {
    textColor = [NSColor alternateSelectedControlTextColor];
    dateColor = textColor;
    titleColor = textColor;
  }
  
  if (object.syncStatus == GBCommitSyncStatusUnmerged)
  {
    CGFloat fadeRatio = 0.35;
    titleColor = [titleColor colorWithAlphaComponent:fadeRatio];
    textColor = [textColor colorWithAlphaComponent:fadeRatio];
    dateColor = [dateColor colorWithAlphaComponent:fadeRatio];
  }
  
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  
	NSMutableDictionary* titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           titleColor, NSForegroundColorAttributeName,
                                           [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
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
  CGFloat verticalShiftForSmallText = 1.0;
  CGFloat x0 = innerRect.origin.x;
  CGFloat y0 = innerRect.origin.y;
  
  // Calculate layout
  
  CGFloat maxDateWidth = innerRect.size.width*dateWidthRatio;
  dateSize.width = (dateSize.width > maxDateWidth ? maxDateWidth : dateSize.width);
  
  NSRect dateRect = NSMakeRect(x0 + innerRect.size.width - dateSize.width,
                               y0 + verticalShiftForSmallText,
                               dateSize.width,
                               dateSize.height);
  
  NSRect titleRect = NSMakeRect(x0,
                                y0 + verticalShiftForSmallText,
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
