#import "GBChange.h"
#import "GBChangeCell.h"

#define kIconImageWidth		16.0

@implementation GBChangeCell

//@synthesize value;

@synthesize isFocused;
@dynamic change;

- (void) dealloc
{
//  self.value = nil;
  [super dealloc];
}

+ (GBChangeCell*) cell
{
  return [[[self alloc] initTextCell:@""] autorelease];
}

- (GBChange*) change
{
  return [self representedObject];
}

- (id) copyWithZone:(NSZone *)zone
{
  NSCell* c = [super copyWithZone:zone];
  c.representedObject = self.representedObject;
  return c;
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)theControlView
{
  NSRect currentFrame = cellFrame; // this will shrink as we draw stuff from left to right
  
  NSWindow* window = [theControlView window];
  
  self.isFocused = ([window firstResponder] && [window firstResponder] == theControlView && 
                    [window isMainWindow] && [window isKeyWindow]);
  
  
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
  
  if ([theControlView isFlipped])
  {
    srcImageRect.origin.y += srcImageRect.size.height + 2;
  }
  else
  {
    srcImageRect.origin.y += 1;
  }
  
  [srcImage compositeToPoint:srcImageRect.origin operation:NSCompositeSourceOver];
  
  
  
  
//  [super drawInteriorWithFrame:cellFrame inView:theControlView];
}

@end
