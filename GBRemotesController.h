@interface GBRemotesController : NSWindowController
{
  id target;
  SEL action;
}

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;

- (IBAction) onOK:(id)sender;

@end
