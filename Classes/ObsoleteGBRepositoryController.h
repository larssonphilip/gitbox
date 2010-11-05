@class ObsoleteGBRepositoryController;

#import "GBRepository.h"
@class GBCommit;
@class GBCommitPromptController;
@class GBCommandsController;
@interface ObsoleteGBRepositoryController : NSWindowController<NSTableViewDelegate>

@property(nonatomic,retain) NSURL* repositoryURL;
@property(nonatomic,retain) GBRepository* repository;

@property(nonatomic,retain) GBCommandsController* commandsController;

@property(nonatomic,retain) IBOutlet NSSplitView* splitView;


#pragma mark View Actions

- (IBAction) toggleSplitViewOrientation:(id)sender;
- (IBAction) commandMenuItem:(id)sender;

@end


