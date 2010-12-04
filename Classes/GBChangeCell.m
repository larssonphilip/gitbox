#import "GBChange.h"
#import "GBChangeCell.h"
#import "NSString+OAStringHelpers.h"

#define kIconImageWidth		16.0

@interface GBChangeCell ()

@property(nonatomic, copy) NSParagraphStyle* truncatingParagraphStyle;

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

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  NSRect currentFrame = cellFrame; // this will shrink as we draw stuff from left to right
  
  NSWindow* window = [theControlView window];
  
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  
  //NSLog(@"%@ isFocused: %d [firstResponder: %@]", [self class], (int)self.isFocused, [window firstResponder]);
  NSLog(@"%@ isHighlighted: %d", [self class], (int)[self isHighlighted]);
  
  BOOL isFlipped = [theControlView isFlipped];
  
  
  GBChange* aChange = [self change];
  
  NSString* srcPath = [aChange.srcURL path];
  if (!srcPath) srcPath = [aChange.dstURL path];
  
  NSString* dstPath = [aChange.dstURL path];
  
  NSImage* srcImage = nil;
  NSImage* dstImage = nil;
  
  // NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef*)@"..."))
  // 
  
  if (srcPath)
  {
    if ([[NSFileManager defaultManager]  fileExistsAtPath:srcPath])
    {
      srcImage = [[NSWorkspace sharedWorkspace] iconForFile:srcPath];
    }
    else
    {
      NSString* ext = [srcPath pathExtension];
      srcImage =  [[NSWorkspace sharedWorkspace] iconForFileType:ext];
    }
  }
  
  
  NSSize imageSize = NSMakeSize(kIconImageWidth, kIconImageWidth);
  
  [srcImage setSize:imageSize];
  
  NSRect srcImageRect = currentFrame;
  srcImageRect.size = imageSize;
  
  
  
  if (isFlipped)
  {
    srcImageRect.origin.y += srcImageRect.size.height;
  }
  
  [srcImage compositeToPoint:srcImageRect.origin operation:NSCompositeSourceOver];
  
  
  
  // Adjust the currentFrame for the text
  
  CGFloat offset = srcImageRect.size.width + 2;
  currentFrame.origin.x += offset;
  currentFrame.size.width -= offset;
  
  
  // Draw the status
  
  {    
    NSColor* textColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
    
    if ([aChange isAddedFile] || [aChange isUntrackedFile])
    {
      textColor = [NSColor colorWithCalibratedRed:0.1 green:0.5 blue:0.0 alpha:1.0];
    }
    else if ([aChange isDeletedFile])
    {
      textColor = [NSColor colorWithCalibratedRed:0.6 green:0.1 blue:0.0 alpha:1.0];
    }
      
    if ([self isHighlighted] && self.isFocused)
    {
      textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.7];
    }
    
    NSFont* font = [NSFont systemFontOfSize:11.0];
    
    NSMutableDictionary* attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             font, NSFontAttributeName,
                                             nil] autorelease];
    
    NSString* status = [aChange.status lowercaseString];
    
    NSSize size = [status sizeWithAttributes:attributes];
    
    if ((size.width / currentFrame.size.width) > 0.5) size.width = round(currentFrame.size.width*0.5);
    
    NSRect statusFrame;
    static CGFloat paddingLeft = 2;
    static CGFloat paddingRight = 2;
    statusFrame.size = size;
    statusFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - size.width) - paddingRight;
    statusFrame.origin.y = currentFrame.origin.y;
    
    if (isFlipped) statusFrame.origin.y += 1;
    
    currentFrame.size.width -= statusFrame.size.width - paddingRight - paddingLeft;
    
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
    
    NSMutableDictionary* titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             textColor, NSForegroundColorAttributeName,
                                             font, NSFontAttributeName,
                                             self.truncatingParagraphStyle, NSParagraphStyleAttributeName,
                                             nil] autorelease];
    
    // If moved, we'll display first the 
    if ([aChange isMovedOrRenamedFile])
    {
      
    }
    else
    {
      
    }
        
  }
  
//  [super drawInteriorWithFrame:cellFrame inView:theControlView];
}



// Overrides NSActionCell/NSTextFieldCell's behaviour when pressed cell is not highlighted, but selected
// This fixes a glitch when pressing the cell.
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
  return NO;
}


@end
