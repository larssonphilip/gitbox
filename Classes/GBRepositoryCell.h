@class GBBaseRepositoryController;
@interface GBRepositoryCell : NSTextFieldCell

@property(assign) BOOL isForeground;
@property(assign) BOOL isFocused;

+ (CGFloat) cellHeight;
- (GBBaseRepositoryController*) repositoryController;

@end
