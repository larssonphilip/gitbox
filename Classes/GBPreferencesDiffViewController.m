#import "OATask.h"
#import "GBChange.h"
#import "GBPreferencesDiffViewController.h"

@implementation GBPreferencesDiffViewController {
	BOOL loadingDiffToolsStatus;
}

+ (GBPreferencesDiffViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesDiffViewController" bundle:nil] autorelease];
}

@synthesize isFileMergeAvailable;
@synthesize isKaleidoscopeAvailable;
@synthesize isChangesAvailable;
@synthesize isTextWranglerAvailable;
@synthesize isBBEditAvailable;
@synthesize isAraxisAvailable;
@synthesize isDiffMergeAvailable;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (NSArray*) diffTools
{
	return [GBChange diffTools];
}

- (void) loadDiffToolsStatus
{
	if (!loadingDiffToolsStatus)
	{
		loadingDiffToolsStatus = YES;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			BOOL fm = !![OATask systemPathForExecutable:@"opendiff"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isFileMergeAvailable = fm;
			});
			BOOL ks = !![OATask systemPathForExecutable:@"ksdiff"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isKaleidoscopeAvailable = ks;
			});
			BOOL ch = !![OATask systemPathForExecutable:@"chdiff"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isChangesAvailable = ch;
			});
			BOOL tw = !![OATask systemPathForExecutable:@"twdiff"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isTextWranglerAvailable = tw;
			});
			BOOL bb = !![OATask systemPathForExecutable:@"bbdiff"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isBBEditAvailable = bb;
			});
			BOOL dm = !![OATask systemPathForExecutable:@"diffmerge"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isDiffMergeAvailable = dm;
			});
			BOOL ax = !![OATask systemPathForExecutable:@"compare"] || !![OATask systemPathForExecutable:@"araxis"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.isAraxisAvailable = ax;
			});
			dispatch_async(dispatch_get_main_queue(), ^{
				loadingDiffToolsStatus = NO;
			});
		});
	}
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
	[self loadDiffToolsStatus];
}



#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesDiff";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesDiff.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Diff Tools", nil);
}

- (void) viewWillAppear
{
	[self loadDiffToolsStatus];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.view.window)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:self.view.window];
			[self loadDiffToolsStatus];
		}
	});
}

- (NSView*)initialKeyView
{
	NSView* v = [self.view viewWithTag:1];
	return v ? v : self.view;
}

@end
