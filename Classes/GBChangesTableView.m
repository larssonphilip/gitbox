#import "GBChangesTableView.h"

@implementation GBChangesTableView
@synthesize preparesImageForDragging;

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
{
  self.preparesImageForDragging = YES;
  NSImage* image = [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
  self.preparesImageForDragging = NO;
  
  return image;
}

@end
