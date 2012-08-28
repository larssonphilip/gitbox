
#import "MASPreferencesViewController.h"

@class SUUpdater;
@interface GBPreferencesUpdatesViewController : NSViewController <MASPreferencesViewController>

@property(unsafe_unretained, nonatomic, readonly) SUUpdater* updater;

+ (GBPreferencesUpdatesViewController*) controller;
- (IBAction)checkForUpdates:(id)sender;

@end

