@class GBRepositoryController;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>
{
  NSTableView* tableView;
  NSArrayController* statusArrayController;
}

@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* statusArrayController; 


#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;


#pragma mark Update

- (void) update;


@end
