@class GBRepository;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>
{
  GBRepository* repository;
  NSTableView* tableView;
  NSArrayController* statusArrayController;
}

@property(nonatomic,retain) GBRepository* repository;
@property(nonatomic,retain) IBOutlet NSTableView* tableView;
@property(nonatomic,retain) IBOutlet NSArrayController* statusArrayController; 


#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;


@end
