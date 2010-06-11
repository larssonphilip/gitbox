@class GBRepository;
@interface GBRemotesController : NSWindowController
{
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) NSMutableArray* remotesDictionaries;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;

- (IBAction) onCancel:(id)sender;
- (IBAction) onOK:(id)sender;

@end
