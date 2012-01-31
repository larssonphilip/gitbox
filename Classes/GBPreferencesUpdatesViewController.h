
#import "MASPreferencesViewController.h"

@class SUUpdater;
@interface GBPreferencesUpdatesViewController : NSViewController <MASPreferencesViewController>

@property(nonatomic, readonly) SUUpdater* updater;

+ (GBPreferencesUpdatesViewController*) controller;
- (IBAction)checkForUpdates:(id)sender;

@end

