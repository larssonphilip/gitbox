#import "GBRepositoryController.h"
@class GBPreferencesController;
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate,
                                   GBRepositoryControllerDelegate>
{
  NSMutableSet* windowControllers;
  NSPanel* preferencesPanel;
  GBPreferencesController* preferencesController;
}

@property(nonatomic,retain) NSMutableSet* windowControllers;
@property(nonatomic,retain) IBOutlet GBPreferencesController* preferencesController;

- (IBAction) openDocument:(id)_;
- (IBAction) showActivityWindow:(id)_;
- (IBAction) releaseNotes:(id)_;

- (BOOL) checkGitVersion;

@end
