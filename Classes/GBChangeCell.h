
@class GBChange;

@interface GBChangeCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,readonly) GBChange* change;

+ (GBChangeCell*) cell;
+ (CGFloat) cellHeight;

@end
