#import "GBWindowControllerWithCallback.h"
@interface GBFileEditingController : GBWindowControllerWithCallback<NSWindowDelegate>
{
  BOOL contentPrepared;
}

@property(nonatomic,strong) NSURL* URL;
@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSArray* linesToAppend;

@property(nonatomic,strong) IBOutlet NSTextView* textView;

+ (GBFileEditingController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
