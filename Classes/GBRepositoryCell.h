@class GBBaseRepositoryController;
@interface GBRepositoryCell : NSTextFieldCell

@property(assign) BOOL isFocused;

+ (CGFloat) cellHeight;
- (GBBaseRepositoryController*) repositoryController;

@end
