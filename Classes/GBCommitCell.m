#import "GBStyle.h"
#import "GBCommit.h"
#import "GBRef.h"
#import "GBRepository.h"
#import "GBStage.h"
#import "GBCommitCell.h"

#import "CGContext+OACGContextHelpers.h"
#import "NSAttributedString+OAAttributedStringHelpers.h"


@interface GBCommitCell ()
@property(nonatomic, retain) NSDictionary* attributes;
@property(nonatomic, retain) GBStage* stage;
@property(nonatomic, assign) BOOL cachedStage;
- (void) drawStageContentInFrame:(NSRect)cellFrame;
- (NSRect) drawTagBadgesAndReturnRemainingRect:(NSRect)rect;
@end


@implementation GBCommitCell

@synthesize isForeground;
@synthesize isFocused;
@dynamic commit;
@synthesize attributes;
@synthesize stage;
@synthesize cachedStage;

- (void)dealloc
{
  [stage release]; stage = nil;
  [attributes release]; attributes = nil;
  [super dealloc];
}

+ (CGFloat) cellHeight
{
  return 40.0;
}

- (NSDateFormatter*) dateFormatterWithTemplate:(NSString*)template
{
  NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
  [formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]]];
  return formatter;
}

- (void) prepareAttributesIfNeeded
{
  if (self.attributes) return;
  
  NSDateFormatter* dateTimeFormatter = [self dateFormatterWithTemplate:@"MMM d, y HH:mm"];
  NSDateFormatter* dateFormatter     = [self dateFormatterWithTemplate:@"MMM d, y"];
  NSDateFormatter* timeFormatter     = [self dateFormatterWithTemplate:@"HH:mm"];
  
  NSMutableParagraphStyle* truncatingParagraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [truncatingParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

  self.attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                     dateTimeFormatter, @"dateTimeFormatter",
                     dateFormatter,     @"dateFormatter",
                     timeFormatter,     @"timeFormatter",
                     truncatingParagraphStyle,    @"truncatingParagraphStyle",
                     nil];
  
}

- (id) attribute:(NSString*)key
{
  return [self.attributes objectForKey:key];
}

+ (GBCommitCell*) cell
{
  GBCommitCell* cell = [[[self alloc] initTextCell:@""] autorelease];
  return cell;
}

- (void) setupCell
{
  [self setSelectable:YES];
  [self setEditable:NO];
}

- (id)initTextCell:(NSString*)string
{
  if ((self = [super initTextCell:string])) [self setupCell];
  return self;
}

- (id)initImageCell:(NSImage*)img
{
  if ((self = [super initImageCell:img])) [self setupCell];
  return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
  if ((self = [super initWithCoder:coder])) [self setupCell];
  return self;
}

- (id) initWithCommit:(GBCommit*)aCommit
{
  if ((self = [self initTextCell:@""]))
  {
    [self setRepresentedObject:aCommit];
  }
  return self;
}

- (id) copyWithZone:(NSZone *)zone
{
  GBCommitCell* cell = [[[self class] alloc] initWithCommit:self.commit];
  cell.isForeground = self.isForeground;
  cell.isFocused = self.isFocused;
  [self prepareAttributesIfNeeded]; // ensure sharing attributes dictionary between multiple copies
  cell.attributes = self.attributes;
  return cell;
}

- (GBCommit*) commit
{
  return [self representedObject];
}

- (void) setCommit:(GBCommit *)aCommit
{
  [self setRepresentedObject:aCommit];
}

- (GBStage*) stage
{
  if (stage) return stage;
  if (!cachedStage)
  {
    cachedStage = YES;
    if ([self.commit isStage])
    {
      stage = [[self.commit asStage] retain];
    }
  }
  return stage;
}

- (NSString*) tooltipString
{
  if (self.stage)
  {
    return NSLocalizedString(@"Working directory and stage status", @"");
  }
  
  GBCommitSyncStatus st = self.commit.syncStatus;
  NSString* statusPrefix = @"";
  if (st != GBCommitSyncStatusNormal)
  {
    if (st == GBCommitSyncStatusUnmerged)
    {
      statusPrefix = NSLocalizedString(@"(Not on the current branch) ", @"Commit");
    }
    else
    {
      statusPrefix = NSLocalizedString(@"(Not pushed) ", @"Commit");
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
        iconImage = [NSImage imageNamed:@"GBCommitCellMarkerHighlighted"];
        //CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.6);
      }
      else
      {
        iconImage = [NSImage imageNamed:@"GBCommitCellMarkerUnmerged"];
        //CGContextSetRGBFillColor(contextRef, 104.0/255.0, 162.0/255.0, 252.0/255.0, 1.0);
        //CGContextSetRGBFillColor(contextRef, 100.0/255.0, 150.0/255.0, 252.0/255.0, 1.0);
      }
    }
    else
    {
      if ([self isHighlighted] && self.isFocused)
      {
        iconImage = [NSImage imageNamed:@"GBCommitCellMarkerHighlighted"];
        //CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.99);
      }
      else
      {
        iconImage = [NSImage imageNamed:@"GBCommitCellMarkerUnpushed"];
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
  if (self.stage)
  {
    [self drawStageContentInFrame:cellFrame];
    return;
  }
  
  {
//    NSGradient* gradient = [[NSGradient alloc]
//                            initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]
//                            endingColor:[NSColor colorWithCalibratedWhite:0.99 alpha:1.0]];
//    if (![self isHighlighted])
//    {
//      [gradient drawInRect:cellFrame angle:90];
//    }
  }
  
  NSRect innerRect = [self innerRectForFrame:cellFrame];
  
  [self drawSyncStatusIconInRect:innerRect];
  
  GBCommit* commit = self.commit;
  
  NSString* title = commit.authorName;
  NSString* date = @"";
  NSString* message = commit.message;
  
  if (commit.date)
  {
    NSDateFormatter* dateFormatter = nil;
    if ([commit.date timeIntervalSinceNow] > -12*3600)
    {
      dateFormatter = [self attribute:@"timeFormatter"];
    }
    else
    {
      if (innerRect.size.width < 250.0)
      {
        dateFormatter = [self attribute:@"dateFormatter"];
      }
      else
      {
        dateFormatter = [self attribute:@"dateTimeFormatter"];
      }
    }
    date = [dateFormatter stringFromDate:commit.date];
  }
  
  // Prepare colors and styles
  
  NSColor* textColor = [NSColor textColor];
  NSColor* titleColor = textColor;
  NSColor* dateColor = [NSColor colorWithCalibratedRed:50.0/255.0 green:100.0/255.0 blue:220.0/255.0 alpha:1.0];
  
  if ([self isHighlighted] && self.isFocused)
  {
    textColor = [NSColor alternateSelectedControlTextColor];
    dateColor = textColor;
    titleColor = textColor;
  }
  
  if ([commit isMerge])
  {
    CGFloat fadeRatio = 0.45;
    NSColor* whiteColor = [NSColor whiteColor];
    titleColor = [titleColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
    textColor = [textColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
    dateColor = [dateColor blendedColorWithFraction:fadeRatio ofColor:whiteColor];
  }
  
  if (commit.syncStatus == GBCommitSyncStatusUnmerged)
  {
    CGFloat fadeRatio = 0.5;
    titleColor = [titleColor colorWithAlphaComponent:fadeRatio];
    textColor = [textColor colorWithAlphaComponent:fadeRatio];
    dateColor = [dateColor colorWithAlphaComponent:fadeRatio];
  }
    
  
  NSParagraphStyle* paragraphStyle = [self attribute:@"truncatingParagraphStyle"];
  
  
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
  
  NSFont* messageFont = [NSFont systemFontOfSize:12.0];

  // Lucida Grande does not ship with italics
//  if ([commit isMerge])
//  {
//    messageFont = [[NSFontManager sharedFontManager] convertFont:messageFont toHaveTrait:NSItalicFontMask];
//  }
  
  NSMutableDictionary* messageAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             messageFont, NSFontAttributeName,
                                             paragraphStyle, NSParagraphStyleAttributeName,
                                             nil] autorelease];
  
  if ([self isHighlighted] && self.isFocused)
  {
    NSShadow* s = [[[NSShadow alloc] init] autorelease];
    [s setShadowOffset:NSMakeSize(0, -1)];
    [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    [titleAttributes setObject:s forKey:NSShadowAttributeName];
    [dateAttributes setObject:s forKey:NSShadowAttributeName];
    [messageAttributes setObject:s forKey:NSShadowAttributeName];
  }

  if ([commit isMerge])
  {
    NSNumber* obliqueness = [NSNumber numberWithFloat:0.2];
    [titleAttributes setObject:obliqueness forKey:NSObliquenessAttributeName];
    [messageAttributes setObject:obliqueness forKey:NSObliquenessAttributeName];
  }

  
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
  
  titleRect = [self drawTagBadgesAndReturnRemainingRect:titleRect];
  
  
  [date drawInRect:dateRect withAttributes:dateAttributes];
  
  if (!commit.searchQuery)
  {
    [title drawInRect:titleRect withAttributes:titleAttributes];
    [message drawInRect:messageRect withAttributes:messageAttributes];
  }
  else
  {
    NSColor* highlightColor = [GBStyle searchHighlightColor];
    if ([self isHighlighted])
    {
      highlightColor = [GBStyle searchSelectedHighlightColor];
    }
    
    NSAttributedString* titleAttrString = [NSAttributedString attributedStringWithString:title 
                                                                              attributes:titleAttributes 
                                                                       highlightedRanges:[commit.foundRangesByProperties objectForKey:@"authorName"]
                                                                          highlightColor:highlightColor];
    NSAttributedString* messageAttrString = [NSAttributedString attributedStringWithString:message 
                                                                              attributes:messageAttributes 
                                                                       highlightedRanges:[commit.foundRangesByProperties objectForKey:@"message"]
                                                                          highlightColor:highlightColor];
    [titleAttrString drawInRect:titleRect];
    [messageAttrString drawInRect:messageRect];
  }
  
  NSString* colorLabel = self.commit.colorLabel;
  if (colorLabel)
  {
    NSImage* cornerImage = [NSImage imageNamed:[NSString stringWithFormat:@"%@Corner.png", colorLabel]];
    if (cornerImage)
    {
      NSSize imageSize = [cornerImage size];
      NSRect imageRect = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - imageSize.width,
                                    cellFrame.origin.y,
                                    imageSize.width, 
                                    imageSize.height);
      [cornerImage drawInRect:imageRect
                   fromRect:(NSRect){.size = imageRect.size, .origin = NSZeroPoint}
                  operation:NSCompositeSourceOver
                   fraction:1.0 
             respectFlipped:YES
                      hints:nil];
    }
  }
}






- (NSRect) drawTagBadgesAndReturnRemainingRect:(NSRect)rect
{
  
  NSArray* tags = [self.commit.repository tagsForCommit:self.commit];
  
  if ([tags count] < 1) return rect;
  
  NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
  [shadow setShadowOffset:NSMakeSize(0, -1)];
  [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
  
	NSMutableDictionary* attrs = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           [NSColor whiteColor], NSForegroundColorAttributeName,
                                           [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
                                           [self attribute:@"truncatingParagraphStyle"], NSParagraphStyleAttributeName,
                                            shadow, NSShadowAttributeName,
                                           nil] autorelease];
  
  BOOL alternateImage = ([self isHighlighted] && self.isFocused);
  
  for (GBRef* tag in tags)
  {
    NSString* tagName = tag.name;
    NSSize size = [tagName sizeWithAttributes:attrs];
    
    const CGFloat paddingLeft = 8.0;
    const CGFloat paddingRight = 8.0;
    const CGFloat spacingRight = 3.0;
    
    CGFloat badgeWidth = paddingLeft + size.width + paddingRight;
    
    CGFloat badgeWidthMin = paddingLeft + paddingRight;
    CGFloat badgeWidthMax = floor(0.333*rect.size.width) - spacingRight;
    badgeWidth = MIN(badgeWidth, badgeWidthMax);
    
    if (badgeWidth <= badgeWidthMin) return rect;
    
    // TODO: draw image
    
    // TODO: draw text
    
    //NSRect textRect = NSMakeRect(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat w#>, <#CGFloat h#>)
    
    // TODO: shift rect, repeat
    
  }
  
  return rect;
}










// Stage cell with status

- (void) drawStageContentInFrame:(NSRect)cellFrame
{
  NSString* title = self.stage.message;
  
  // Prepare colors and styles
  
  NSColor* textColor = [NSColor textColor];
  
  if ([self isHighlighted] && self.isFocused)
  {
    textColor = [NSColor alternateSelectedControlTextColor];
  }
  
  NSParagraphStyle* paragraphStyle = [self attribute:@"truncatingParagraphStyle"];
  
  NSFont* font = nil;
  if ([self.stage isDirty])
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
  
  if ([self isHighlighted] && self.isFocused)
  {
    NSShadow* s = [[[NSShadow alloc] init] autorelease];
    [s setShadowOffset:NSMakeSize(0, -1)];
    [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    [titleAttributes setObject:s forKey:NSShadowAttributeName];
  }
  
  
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



//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)theControlView
- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  [self prepareAttributesIfNeeded];
  
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  NSWindow* window = [theControlView window];
  
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  self.isForeground = [window isMainWindow];
  
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
  [pool release];
}




@end
