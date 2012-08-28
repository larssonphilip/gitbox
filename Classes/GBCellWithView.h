
@interface GBCellWithView : NSTextFieldCell
@property(nonatomic, weak) NSView* view;
@property(nonatomic, assign) CGFloat verticalOffset;
@property(nonatomic, assign) BOOL isViewManagementDisabled;

+ (GBCellWithView*) cellWithView:(NSView*)aView;

@end
