#import "GBRepositoryController.h"
@class GBPreferencesController;
@class GBMainWindowController;
@interface GBAppDelegate : NSObject <NSApplicationDelegate, 
                                   NSOpenSavePanelDelegate>
{
  GBMainWindowController* windowController;
  GBPreferencesController* preferencesController;
}

@property(nonatomic,retain) GBMainWindowController* windowController;
@property(nonatomic,retain) IBOutlet GBPreferencesController* preferencesController;

- (IBAction) openDocument:(id)_;
- (IBAction) showActivityWindow:(id)_;
- (IBAction) releaseNotes:(id)_;
- (IBAction) showDiffToolPreferences:(id)_;

- (BOOL) checkGitVersion;

@end
