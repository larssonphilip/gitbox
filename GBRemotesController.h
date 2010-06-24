@class GBRepository;
@interface GBRemotesController : NSWindowController
{
  GBRepository* repository;
  NSMutableArray* remotesDictionaries;
  id target;
  SEL finishSelector;
  SEL cancelSelector;
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) NSMutableArray* remotesDictionaries;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL finishSelector;
@property(nonatomic,assign) SEL cancelSelector;

+ (id) controller;

- (IBAction) onCancel:(id)sender;
- (IBAction) onOK:(id)sender;

@end
