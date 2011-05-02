#import "GBWindowControllerWithCallback.h"

@class GBRepository;
@interface GBRemotesController : GBWindowControllerWithCallback

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) NSMutableArray* remotesDictionaries;

+ (id) controller;

- (IBAction) onCancel:(id)sender;
- (IBAction) onOK:(id)sender;

@end
