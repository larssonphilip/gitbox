@class GBRepository;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate>
{
  NSTableView* tableView;
  NSArrayController* statusArrayController;
}

@property(retain) GBRepository* repository;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* statusArrayController; 


#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;


@end
