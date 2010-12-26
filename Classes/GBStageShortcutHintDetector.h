
@interface GBStageShortcutHintDetector : NSObject

+ (GBStageShortcutHintDetector*) detectorWithView:(NSView*)aView;

// A view which should be hidden by default and shown with a tip
@property(nonatomic, retain) NSView* view;

// A callback from the similar delegate 
- (void) textView:(NSTextView*)aTextView didChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString;

- (void) reset;

@end
