
@class GBChange;

@interface GBChangeCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isFocused;
@property(unsafe_unretained, nonatomic,readonly) GBChange* change;

+ (GBChangeCell*) cell;
+ (CGFloat) cellHeight;

@end
