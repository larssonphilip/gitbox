
@interface GBCellWithView : NSTextFieldCell
@property(nonatomic, assign) NSView* view;

+ (GBCellWithView*) cellWithView:(NSView*)aView;

@end
