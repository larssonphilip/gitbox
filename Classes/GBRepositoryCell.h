@class GBBaseRepositoryController;
@interface GBRepositoryCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isForeground;
@property(nonatomic,assign) BOOL isFocused;

+ (CGFloat) cellHeight;
- (GBBaseRepositoryController*) repositoryController;

@end
