@interface GBCommitController : NSWindowController
{
  NSString* message;
  
  id target;
  SEL finishSelector;
  SEL cancelSelector;
}

@property(retain) NSString* message;

@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;

- (IBAction) onOK:(id)sender;
- (IBAction) onCancel:(id)sender;

@end
