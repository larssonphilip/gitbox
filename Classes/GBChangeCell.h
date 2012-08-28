
@class GBChange;

@interface GBChangeCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isFocused;
@property(weak, nonatomic,readonly) GBChange* change;

+ (GBChangeCell*) cell;
+ (CGFloat) cellHeight;

@end
