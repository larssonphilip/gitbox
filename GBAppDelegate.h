#import "GBRepositoryController.h"
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate,
                                   GBRepositoryControllerDelegate>
{
}

@property(nonatomic,retain) NSMutableSet* windowControllers;

- (IBAction) openDocument:(id)sender;
- (IBAction) showActivityWindow:(id)sender;

@end
