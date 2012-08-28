#import "GBWindowControllerWithCallback.h"

@interface GBConfirmationController : GBWindowControllerWithCallback

@property(nonatomic, strong) IBOutlet NSTextField* promptTextField;
@property(nonatomic, strong) IBOutlet NSTextField* descriptionTextField;
@property(nonatomic, strong) IBOutlet NSButton* okButton;

+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description;
+ (GBConfirmationController*) controllerWithPrompt:(NSString*)prompt description:(NSString*)description ok:(NSString*)ok;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
