@class GBBaseRepositoryController;
@interface GBRepositoryCell : NSTextFieldCell

@property(nonatomic,assign) BOOL isForeground;
@property(nonatomic,assign) BOOL isFocused;
@property(nonatomic,assign) BOOL isDragged;

+ (CGFloat) cellHeight;
- (GBBaseRepositoryController*) repositoryController;

@end
