#import "MASPreferencesViewController.h"

@interface GBPreferencesDiffViewController : NSViewController <MASPreferencesViewController>

+ (GBPreferencesDiffViewController*) controller;

@property(assign) BOOL isFileMergeAvailable;
@property(assign) BOOL isKaleidoscopeAvailable;
@property(assign) BOOL isChangesAvailable;
@property(assign) BOOL isTextWranglerAvailable;
@property(assign) BOOL isBBEditAvailable;
@property(assign) BOOL isAraxisAvailable;
@property(assign) BOOL isDiffMergeAvailable;

- (NSArray*) diffTools;

@end
