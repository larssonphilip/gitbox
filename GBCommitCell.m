#import "GBCommit.h"
#import "GBCommitCell.h"

@implementation GBCommitCell

- (GBCommit*) commit
{
  return [self representedObject];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
	// blue highlight: [NSColor alternateSelectedControlColor];
  // white text in highlight: [NSColor alternateSelectedControlTextColor];
  
  NSRect innerRect = NSInsetRect(cellFrame, 10.0, 10.0);
  
  GBCommit* object = [self commit];
  
  NSString* title = @"object.authorName";
  NSString* date = @"12:34 Fake Date";
  NSString* message = @"object.message";
  
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
   (0;0)
  */
  
  // Layout constants
  
  CGFloat dateWidthRatio = 0.4; // 40% of the width
  CGFloat titleDatePadding = 5.0;
  CGFloat titleMessagePadding = 3.0;
  
  // Calculate layout
  
  CGFloat maxDateWidth = innerRect.size.width*dateWidthRatio;
  dateSize.width = (dateSize.width > maxDateWidth ? maxDateWidth : dateSize.width);
  
  NSRect dateRect = NSMakeRect(innerRect.size.width - dateSize.width,
                               0.0,
                               dateSize.width,
                               dateSize.height);
  
  NSRect titleRect = NSMakeRect(0.0,
                                innerRect.size.height - titleSize.height,
                                innerRect.size.width - dateSize.width - titleDatePadding, 
                                titleSize.height);

  NSRect messageRect = NSMakeRect(0.0, 
                                  0.0, 
                                  innerRect.size.width,
                                  innerRect.size.height - titleSize.height - titleMessagePadding);
  
  // draw
  
  [date drawInRect:dateRect withAttributes:dateAttributes];
//  [title drawInRect:titleRect withAttributes:titleAttributes];
//  [message drawInRect:messageRect withAttributes:messageAttributes];
  
}

@end
