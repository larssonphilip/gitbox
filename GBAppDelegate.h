#import "GBRepositoryController.h"
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate,
                                   GBRepositoryControllerDelegate>
{
  NSMutableSet* windowControllers; 
}

@property(nonatomic,retain) NSMutableSet* windowControllers;

- (IBAction) openDocument:(id)sender;

@end
