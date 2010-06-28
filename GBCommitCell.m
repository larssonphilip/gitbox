#import "GBCommit.h"
#import "GBCommitCell.h"

#import "CGContext+OACGContextHelpers.h"

@implementation GBCommitCell

@synthesize isFocused;
@dynamic commit;
- (GBCommit*) commit
{
  return [self representedObject];
}

+ (CGFloat) cellHeight
{
  return 40.0;
}

- (NSString*) tooltipString
{
  GBCommitSyncStatus st = self.commit.syncStatus;
  NSString* statusPrefix = @"";
  if (st != GBCommitSyncStatusNormal)
  {
    if (st == GBCommitSyncStatusUnmerged)
    {
      statusPrefix = @"(Not on the current branch) ";
    }
    else
    {
      statusPrefix = @"(Not pushed) ";
    }
  }
  return [statusPrefix stringByAppendingString:[self.commit tooltipMessage]];
}

- (NSRect) innerRectForFrame:(NSRect)cellFrame
{
  NSRect innerRect = NSInsetRect(cellFrame, 0.0, 2.0);
  
  CGFloat leftOffset = 19.0;
  CGFloat rightOffset = 16.0;
  innerRect.origin.x += leftOffset;
  innerRect.size.width -= (leftOffset + rightOffset);
  
  return innerRect;
}

- (void) drawSyncStatusIconInRect:(NSRect)rect
{
  GBCommitSyncStatus st = self.commit.syncStatus;
//  CGContextRef contextRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  
  
  NSImage* iconImage = nil;
  
  if (st != GBCommitSyncStatusNormal)
  {
    if (st == GBCommitSyncStatusUnmerged)
    {
      if ([self isHighlighted] && self.isFocused)
      {
        iconImage = [NSImage imageNamed:@"commit-marker-highlighted"];
        //CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.6);
      }
      else
      {
        iconImage = [NSImage imageNamed:@"commit-marker-unmerged"];
        //CGContextSetRGBFillColor(contextRef, 104.0/255.0, 162.0/255.0, 252.0/255.0, 1.0);
        //CGContextSetRGBFillColor(contextRef, 100.0/255.0, 150.0/255.0, 252.0/255.0, 1.0);
      }
    }
    else
    {
      if ([self isHighlighted] && self.isFocused)
      {
        iconImage = [NSImage imageNamed:@"commit-marker-highlighted"];
        //CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.99);
      }
      else
      {
        iconImage = [NSImage imageNamed:@"commit-marker-unpushed"];
        //CGContextSetRGBFillColor(contextRef, 255.0/255.0, 125.0/255.0, 0.0/255.0, 1.0);
        //CGContextSetRGBFillColor(contextRef, 94.0/255.0, 220.0/255.0, 50.0/255.0, 1.0);
      }
    }
    if (iconImage)
    {
      NSRect imageRect = rect;
      imageRect.origin.x -= 14.0;
      imageRect.origin.y += 4.0;
      imageRect.size = [iconImage size];
      [iconImage drawInRect:imageRect
                   fromRect:(NSRect){.size = imageRect.size, .origin = NSZeroPoint}
                  operation:NSCompositeSourceOver
                   fraction:1.0 
             respectFlipped:YES
                      hints:nil];
    }
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
  
  if ([self isHighlighted] && self.isFocused)
  {
    textColor = [NSColor alternateSelectedControlTextColor];
    dateColor = textColor;
    titleColor = textColor;
  }
  
  if ([object isMerge])
  {
    CGFloat fadeRatio = 0.5;
    NSColor* whiteColor = [NSColor whiteColor];
    titleColor = [titleColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
    textColor = [textColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
    dateColor = [dateColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
  }
  
  if (object.syncStatus == GBCommitSyncStatusUnmerged)
  {
    CGFloat fadeRatio = 0.5;
    titleColor = [titleColor colorWithAlphaComponent:fadeRatio];
    textColor = [textColor colorWithAlphaComponent:fadeRatio];
    dateColor = [dateColor colorWithAlphaComponent:fadeRatio];
  }
    
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
  
  
	NSMutableDictionary* titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           titleColor, NSForegroundColorAttributeName,
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
  CGFloat verticalShiftForSmallText = 2.0;
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
  NSWindow* window = [theControlView window];
  
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  
  [[NSColor whiteColor] setFill];
  NSRectFill(cellFrame);
  
  NSColor* backgroundColor = [NSColor controlBackgroundColor];
  
  if ([self isHighlighted])
  {
    if (isFocused)
    {
      backgroundColor = [NSColor alternateSelectedControlColor];
    }
    else
    {
      backgroundColor = [NSColor secondarySelectedControlColor];
    }
    
//    [backgroundColor set];
//    NSRectFill(cellFrame);

    CGRect rect = NSRectToCGRect(cellFrame);
    
    NSColor* deviceColor = [backgroundColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    CGFloat r = 0.0;
    CGFloat g = 0.0;
    CGFloat b = 0.0;
    CGFloat a = 0.0;
    [deviceColor getRed:&r green:&g blue:&b alpha:&a];
    
    CGFloat k1 = 0.15;
    CGFloat k2 = 1-0.07;
    
    CGColorRef color1 = CGColorCreateGenericRGB(k1+r*(1-k1), k1+g*(1-k1), k1+b*(1-k1), a);
    CGColorRef color2 = CGColorCreateGenericRGB(r, g, b, a);
    CGColorRef color3 = CGColorCreateGenericRGB(r*k2, g*k2, b*k2, a);
    
    CGColorRef colorsList[] = { color1, color2, color3 };
    CFArrayRef colors = CFArrayCreate(NULL, (const void**)colorsList, sizeof(colorsList) / sizeof(CGColorRef), &kCFTypeArrayCallBacks);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, NULL);
    
    CGContextRef context = CGContextCurrentContext();
    CGContextDrawLinearGradient(context, 
                                gradient,
                                rect.origin,
                                CGPointMake(rect.origin.x, rect.origin.y + rect.size.height), 
                                0);
    
    CFRelease(colorSpace);
    CFRelease(colors);
    
    CFRelease(color1);
    CFRelease(color2);
    CFRelease(color3);
    CFRelease(gradient);
  }
  else
  {
    [backgroundColor set];
    NSRectFill(cellFrame);
    
    [[NSColor colorWithDeviceWhite:0.96 alpha:1.0] set];
    NSRectFill(NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height - 1.0, cellFrame.size.width, 1.0));
  }
  
  [self drawContentInFrame:cellFrame];
}


- (id) copyWithZone:(NSZone *)zone
{
  GBCommitCell* c = [super copyWithZone:zone];
  c.representedObject = self.representedObject;
  return c;
}



@end
