@class GBRepository;
@interface GBRemotesController : NSWindowController
{
}

@property(retain) GBRepository* repository;
@property(retain) NSMutableArray* remotesDictionaries;
@property(assign) id target;
@property(assign) SEL finishSelector;
@property(assign) SEL cancelSelector;

- (IBAction) onCancel:(id)sender;
- (IBAction) onOK:(id)sender;

@end
