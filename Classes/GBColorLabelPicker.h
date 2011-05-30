
extern NSString* const GBColorLabelClear;
extern NSString* const GBColorLabelRed;
extern NSString* const GBColorLabelOrange;
extern NSString* const GBColorLabelYellow;
extern NSString* const GBColorLabelGreen;
extern NSString* const GBColorLabelBlue;
extern NSString* const GBColorLabelPurple;
extern NSString* const GBColorLabelGray;

@interface GBColorLabelPicker : NSView

@property(nonatomic, retain) NSString* value;
@property(nonatomic, retain) id representedObject;
@property(nonatomic, assign) id target; // if target is nil, first responder receives an action
@property(nonatomic, assign) SEL action;

+ (id) pickerWithTarget:(id)target action:(SEL)action object:(id)representedObject;

@end
