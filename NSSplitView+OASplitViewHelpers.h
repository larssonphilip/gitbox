@interface NSSplitView (OASplitViewHelpers)

/*
 PURPOSE:
 
   When splitview is autoresized by dragging a parent view or a window, 
   subviews are equally resizes without asking delegate to contraint their sizes.
   This method helps to constrain first view size in case of autoresizing.
   
   Note: do not forget to also implement splitView:constrainMinCoordinate:ofSubviewAt:
 
 EXAMPLE:
   
   // In your delegate implement these methods:
   
   - (void) splitView:(NSSplitView*)aSplitView 
            resizeSubviewsWithOldSize:(NSSize)oldSize
   {
     [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:LIMIT];
   }

   - (CGFloat)splitView:(NSSplitView*) aSplitView 
              constrainMinCoordinate:(CGFloat)proposedMin 
              ofSubviewAt:(NSInteger)dividerIndex
   {
     return LIMIT;
   }
*/

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize firstViewSizeLimit:(CGFloat)firstViewSizeLimit;

@end
