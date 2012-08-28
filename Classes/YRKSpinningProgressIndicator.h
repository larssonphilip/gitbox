
@interface YRKSpinningProgressIndicator : NSView

@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawsBackground;
@property (nonatomic, assign) BOOL usesThreadedAnimation;
@property (nonatomic, assign) BOOL actsAsCell;

@property (nonatomic, assign, getter=isIndeterminate) BOOL indeterminate;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) double maxValue;

- (void)stopAnimation:(id)sender;
- (void)startAnimation:(id)sender;

@end
