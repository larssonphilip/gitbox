#import "GBRepositoryController.h"
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate,
                                   GBRepositoryControllerDelegate>
{
  NSMutableSet* windowControllers;
  NSPanel* preferencesPanel;
}

@property(nonatomic,retain) NSMutableSet* windowControllers;
@property(nonatomic,retain) IBOutlet NSPanel* preferencesPanel;

- (IBAction) openDocument:(id)sender;
- (IBAction) showActivityWindow:(id)sender;

- (BOOL) checkGitVersion;

@end
