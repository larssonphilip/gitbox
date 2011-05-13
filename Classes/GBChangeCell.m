#import "GBStyle.h"
#import "GBChange.h"
#import "GBChangeCell.h"
#import "GBChangesTableView.h"
#import "NSString+OAStringHelpers.h"

#define kIconImageWidth		16.0

@interface GBChangeCell ()
@property(nonatomic, copy) NSParagraphStyle* truncatingParagraphStyle;
- (void) drawPath:(NSString*)aPath inRect:(NSRect)aRect withAttributes:(NSDictionary*)attributes;
@end



@implementation GBChangeCell

@synthesize truncatingParagraphStyle;

@synthesize isFocused;
@dynamic change;

- (void) dealloc
{
  self.truncatingParagraphStyle = nil;
  [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
  // Do not use super implementation which copies the ivar pointers and fucks up refcounts
  GBChangeCell* c = [[[self class] alloc] initTextCell:@""]; 
  c.representedObject = self.representedObject;
  c.truncatingParagraphStyle = self.truncatingParagraphStyle;
  [c setShowsFirstResponder:[self showsFirstResponder]];
  return c;
}

+ (GBChangeCell*) cell
{
  GBChangeCell* cell = [[[self alloc] initTextCell:@""] autorelease];
  [cell setControlSize:NSSmallControlSize];
  
  NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle new] autorelease];
  [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

  cell.truncatingParagraphStyle = [[paragraphStyle copy] autorelease];
  return cell;
}

+ (CGFloat) cellHeight
{
  return 18.0 - 1; // 1 will be added by a selection, in AppKit
}







- (GBChange*) change
{
  return [self representedObject];
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(GBChangesTableView*)theControlView
{
  if (![theControlView isKindOfClass:[GBChangesTableView class]]) return;
  BOOL isDragging = theControlView.preparesImageForDragging;
  
  NSRect currentFrame = cellFrame; // this will shrink as we draw stuff from left to right
  
  NSWindow* window = [theControlView window];
  
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  
  //NSLog(@"%@ isFocused: %d [firstResponder: %@]", [self class], (int)self.isFocused, [window firstResponder]);
  //NSLog(@"%@ isHighlighted: %d", [self class], (int)[self isHighlighted]);
  
  BOOL isFlipped = [theControlView isFlipped];
  
  
  GBChange* aChange = [self change];
  
  NSURL* srcURL = aChange.srcURL;
  if (!srcURL) srcURL = aChange.dstURL;
  
  NSURL* dstURL = aChange.dstURL;
  
  NSImage* srcIcon = [aChange srcIconOrDstIcon];
    
  NSSize iconSize = NSMakeSize(kIconImageWidth, kIconImageWidth);
  
  [srcIcon setSize:iconSize];
  
  static CGFloat leftOffsetLikeInFinder = 5;
  currentFrame.origin.x += leftOffsetLikeInFinder;
  currentFrame.size.width -= leftOffsetLikeInFinder;
  
  NSRect srcIconRect = currentFrame;
  srcIconRect.size = iconSize;
  
  if (isFlipped)
  {
    srcIconRect.origin.y += srcIconRect.size.height;
  }
  
  [srcIcon compositeToPoint:srcIconRect.origin operation:NSCompositeSourceOver];
  
  
  
  // Adjust the currentFrame for the text
  
  CGFloat offsetAfterIcon = srcIconRect.size.width + 6;
  currentFrame.origin.x += offsetAfterIcon;
  currentFrame.size.width -= offsetAfterIcon;
  
  // Draw the status
  
  if (!isDragging)
  {
    NSColor* textColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
    
//    if ([aChange isAddedFile] || [aChange isUntrackedFile])
//    {
//      textColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0]; // [NSColor colorWithCalibratedWhite:0.3 alpha:1.0]; //[NSColor colorWithCalibratedRed:0.1 green:0.5 blue:0.0 alpha:1.0];
//    }
//    else if ([aChange isDeletedFile])
//    {
//      textColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0]; //[NSColor colorWithCalibratedRed:0.6 green:0.1 blue:0.0 alpha:1.0];
//    }
      
    if ([self isHighlighted] && self.isFocused)
    {
      textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.7];
    }
    
    NSFont* font = [NSFont systemFontOfSize:11.0];
    
    NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             font, NSFontAttributeName,
                                             self.truncatingParagraphStyle, NSParagraphStyleAttributeName,
                                             nil] autorelease];
    
    NSString* status = [aChange.status lowercaseString];
    
    NSSize size = [status sizeWithAttributes:attributes];
    
    if ((size.width / currentFrame.size.width) > 0.5) size.width = round(currentFrame.size.width*0.5);
    
    NSRect statusFrame;
    static CGFloat paddingLeft = 4;
    static CGFloat paddingRight = 6;
    statusFrame.size = size;
    statusFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - size.width) - paddingRight;
    statusFrame.origin.y = currentFrame.origin.y;
    
    if (isFlipped) statusFrame.origin.y += 2;
    
    static CGFloat minStatusColumnSizeToMakeItPretty = 56; // we could use NSParagraphStyle to set alignment, but this way it is simpler for now
    currentFrame.size.width -= round(MAX(statusFrame.size.width, minStatusColumnSizeToMakeItPretty) + paddingRight + paddingLeft);
    [status drawInRect:statusFrame withAttributes:attributes];
  }
  
  
  
  
  // Draw the text
  
  {
    NSColor* textColor = [NSColor textColor];
    
    if ([self isHighlighted] && self.isFocused)
    {
      textColor = [NSColor alternateSelectedControlTextColor];
    }
    
    NSFont* font = [NSFont systemFontOfSize:12.0];
    
    NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             font, NSFontAttributeName,
                                             self.truncatingParagraphStyle, NSParagraphStyleAttributeName,
                                             nil] autorelease];

    // If moved, we'll display the first path, then arrow and icon+relative path for the second one
    if ([aChange isMovedOrRenamedFile] && dstURL && !isDragging)
    {
      // - Calculate how much space is needed for icon and arrow
      // - Calculate sizes for texts
      // - If the remaining space is enough for both names, draw them in full
      // - If not, try to give more space to dstURL, but not more than max(0.65*width, width - srcWidth) and adjust both sizes
      // - Draw.
      static CGFloat arrowLeftPadding = 4.0;
      static CGFloat arrowRightPadding = 4.0;
      static CGFloat iconRightPadding = 6.0;
      CGFloat arrowWidth = [@"→" sizeWithAttributes:attributes].width;
      
      NSString* srcPath = [srcURL relativePath];
      NSString* dstPath = [[dstURL relativePath] relativePathToDirectoryPath:[srcPath stringByDeletingLastPathComponent]];
      
      NSSize srcSize = [srcPath sizeWithAttributes:attributes];
      NSSize dstSize = [dstPath sizeWithAttributes:attributes];
      
      CGFloat remainingWidth = currentFrame.size.width - (arrowLeftPadding + arrowWidth + arrowRightPadding + iconSize.width + iconRightPadding);
      
      if (srcSize.width + dstSize.width > remainingWidth)
      {
        CGFloat maxDstWidth = round(MAX(0.65*remainingWidth, remainingWidth - srcSize.width));
        if (dstSize.width > maxDstWidth)
        {
          dstSize.width = maxDstWidth;
        }
        srcSize.width = remainingWidth - dstSize.width;
      }
      
      srcSize.width = round(srcSize.width);
      dstSize.width = round(dstSize.width);
      
      
      // Draw src
      
      NSRect srcRect = currentFrame;
      srcRect.size = srcSize;

      currentFrame.origin.x += srcSize.width;
      currentFrame.size.width -= srcSize.width;
      
      // TODO: shrink the path in a smart way
      [self drawPath:srcPath inRect:srcRect withAttributes:attributes];

      // Draw arrow

      currentFrame.origin.x += arrowLeftPadding;
      currentFrame.size.width -= arrowLeftPadding;
      
      
      NSRect arrowRect = currentFrame;
      arrowRect.size.width = arrowWidth;

      [@"→" drawInRect:arrowRect withAttributes:attributes];
      
      currentFrame.origin.x += arrowRightPadding + arrowWidth;
      currentFrame.size.width -= arrowRightPadding + arrowWidth;
      
      
      // Draw icon

      NSImage* dstIcon = srcIcon;
      if (![[srcPath pathExtension] isEqualToString:[dstPath pathExtension]])
      {
        dstIcon = [aChange dstIcon];
        [dstIcon setSize:iconSize];
      }
      
      NSRect dstIconRect = srcIconRect;
      dstIconRect.origin.x = currentFrame.origin.x;
      
      [dstIcon compositeToPoint:dstIconRect.origin operation:NSCompositeSourceOver];
      
      currentFrame.origin.x += offsetAfterIcon;
      currentFrame.size.width -= offsetAfterIcon;
      
      
      // Draw dst
      
      // TODO: shrink the path in a smart way
      [self drawPath:dstPath inRect:currentFrame withAttributes:attributes];
    }
    else
    {
      NSURL* url = srcURL;
      if (dstURL && isDragging)
      {
        url = dstURL;
      }
      
      [self drawPath:[url relativePath] inRect:currentFrame withAttributes:attributes];
    }
        
  }
  
//  [super drawInteriorWithFrame:cellFrame inView:theControlView];
}

- (void) drawPath:(NSString*)aPath inRect:(NSRect)aRect withAttributes:(NSDictionary*)attributes
{
  if (!aPath) return;
  
  GBChange* aChange = [self change];
  if (aChange.searchQuery)
  {
    NSColor* highlightColor = [GBStyle searchHighlightColor];
    if ([self isHighlighted])
    {
      highlightColor = [GBStyle searchSelectedHighlightColor];
    }
    
    NSMutableAttributedString* attributedString = [[[NSMutableAttributedString alloc] initWithString:aPath] autorelease];
    [attributedString beginEditing];
    
    // Set base attributes
    NSRange fullRange = NSMakeRange(0, [aPath length]);
    [attributedString addAttributes:attributes range:fullRange];
    
    // Highlight matched path substrings
    for (NSString* substring in aChange.highlightedPathSubstrings)
    {
      NSRange range = [aPath rangeOfString:substring options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
      if (range.length > 0)
      {
        [attributedString addAttribute:NSBackgroundColorAttributeName value:highlightColor range:range];
      }
    }
    
    // Highlight matches in diff by drawing underline
    if (aChange.containsHighlightedDiffLines)
    {
      NSColor* highlightColor = [GBStyle searchHighlightUnderlineColor];
      if ([self isHighlighted])
      {
        highlightColor = [GBStyle searchSelectedHighlightUnderlineColor];
      }
      [attributedString addAttribute:NSUnderlineColorAttributeName value:highlightColor range:fullRange];
      [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleThick] range:fullRange];
    }
    
    [attributedString endEditing];
    [attributedString drawInRect:aRect];
  }
  else
  {
    [aPath drawInRect:aRect withAttributes:attributes];
  }  
}


// Overrides NSActionCell/NSTextFieldCell's behaviour when pressed cell is not highlighted, but selected
// This fixes a glitch when pressing the cell.
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
  return NO;
}



@end
