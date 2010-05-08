#import "GBWindowController.h"
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate,
                                   GBWindowControllerDelegate>
{
  NSMutableSet* windowControllers; 
}

@property(nonatomic,retain) NSMutableSet* windowControllers;

- (IBAction) openDocument:(id)sender;

@end
