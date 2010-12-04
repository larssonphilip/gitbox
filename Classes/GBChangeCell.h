
@class GBChange;

@interface GBChangeCell : NSTextFieldCell

//@property(nonatomic,copy) NSString* value;

@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,readonly) GBChange* change;

+ (GBChangeCell*) cell;

@end
