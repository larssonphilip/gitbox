@interface GBRemotesController : NSWindowController
{
  id target;
  SEL action;
}

@property(assign) id target;
@property(assign) SEL action;

- (IBAction) onOK:(id)sender;

@end
