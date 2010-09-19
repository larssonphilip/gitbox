@class GBRepositoryController;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>
{
  GBRepositoryController* repositoryController;
  NSTableView* tableView;
  NSArrayController* statusArrayController;
}

@property(assign) GBRepositoryController* repositoryController;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* statusArrayController; 


#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;


@end
