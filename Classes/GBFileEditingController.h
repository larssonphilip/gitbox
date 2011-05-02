#import "GBWindowControllerWithCallback.h"
@interface GBFileEditingController : GBWindowControllerWithCallback<NSWindowDelegate>
{
  BOOL contentPrepared;
}

@property(nonatomic,retain) NSURL* URL;
@property(nonatomic,retain) NSString* title;
@property(nonatomic,retain) NSArray* linesToAppend;

@property(nonatomic,retain) IBOutlet NSTextView* textView;

+ (GBFileEditingController*) controller;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
