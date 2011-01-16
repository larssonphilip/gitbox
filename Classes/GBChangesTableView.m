#import "GBChangesTableView.h"
#include <Quartz/Quartz.h>
#include <QuickLook/QuickLook.h>

@implementation GBChangesTableView
@synthesize preparesImageForDragging;

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
{
  self.preparesImageForDragging = YES;
  NSImage* image = [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
  self.preparesImageForDragging = NO;
  
  return image;
}

- (void)keyDown:(NSEvent*)theEvent
{
  NSString* key = [theEvent charactersIgnoringModifiers];
  if([key isEqual:@" "])
  {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
    {
      [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    }
    else
    {
      [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
  }
  else
  {
    [super keyDown:theEvent];
  }
}

@end
