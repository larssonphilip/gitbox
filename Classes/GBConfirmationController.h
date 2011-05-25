#import "GBWindowControllerWithCallback.h"

@interface GBConfirmationController : GBWindowControllerWithCallback

@property(nonatomic, retain) IBOutlet NSTextField* promptTextField;
@property(nonatomic, retain) IBOutlet NSTextField* descriptionTextField;
@property(nonatomic, retain) IBOutlet NSButton* okButton;

+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description;
+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description ok:(NSString*)ok;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
