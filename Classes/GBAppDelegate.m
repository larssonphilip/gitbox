#import "GBApplication.h"
#import "GBAppDelegate.h"
#import "GBRootController.h"
#import "GBRepositoriesController.h"
#import "GBMainWindowController.h"
#import "GBActivityController.h"

#import "MASPreferencesWindowController.h"
#import "GBPreferencesDiffViewController.h"
#import "GBPreferencesGithubViewController.h"
#import "GBPreferencesConfigViewController.h"
#import "GBPreferencesIgnoreViewController.h"
#import "GBPreferencesLicenseViewController.h"
#import "GBPreferencesUpdatesViewController.h"

#import "GBPromptController.h"
#import "GBSidebarController.h"
#import "GBAskPassServer.h"

#import "GBChange.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "NSData+OADataHelpers.h"

#import "GBOptimizeRepositoryController.h"

#import "OALicenseNumberCheck.h"
#import "OATask.h"

#import "GBAsyncUpdater.h"

#define DEBUG_iRate 0

#if DEBUG_iRate
#warning Debugging iRate
#endif

#import "iRate.h"

#if !GITBOX_APP_STORE
#import "Sparkle/Sparkle.h"
#endif

@interface GBAppDelegate () <NSApplicationDelegate, NSOpenSavePanelDelegate, iRateDelegate>

@property(nonatomic) GBRootController* rootController;
@property(nonatomic) GBMainWindowController* windowController;
@property(nonatomic) MASPreferencesWindowController* preferencesController;
@property(nonatomic) NSMutableArray* URLsToOpenAfterLaunch;

@property(nonatomic) IBOutlet NSTextView* licenseTextView;
@property(nonatomic) IBOutlet NSMenuItem* checkForUpdatesMenuItem;
@property(nonatomic) IBOutlet NSMenuItem* welcomeMenuItem;
@property(nonatomic) IBOutlet NSMenuItem* rateInAppStoreMenuItem;

@end

@implementation GBAppDelegate {
	NSUInteger _diffToolsControllerIndex;
	NSUInteger _licenseControllerIndex;
}

+ (void) initialize
{
#if GITBOX_APP_STORE || DEBUG_iRate
	// http://itunes.apple.com/us/app/gitbox/id403388357
	[iRate sharedInstance].appStoreID = 403388357;
	[iRate sharedInstance].eventsUntilPrompt = 200; // 200 commits before prompt
#endif
}

+ (GBAppDelegate*) instance
{
	return (GBAppDelegate*)[NSApp delegate];
}










#pragma mark - Actions






- (IBAction) rateInAppStore:(id)sender
{
#if GITBOX_APP_STORE || DEBUG_iRate  
	[[iRate sharedInstance] openRatingsPageInAppStore];
#else
	NSString* purchaseURLString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBAppStoreURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:purchaseURLString]];
#endif
}

- (IBAction) showMainWindow:(id)sender
{
	[self.windowController showWindow:self];
}

- (IBAction) showPreferences:(id)sender
{
	[self.preferencesController showWindow:sender];
}

- (IBAction) checkForUpdates:(id)sender
{
#if !GITBOX_APP_STORE
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
#else
	[self rateInAppStore:sender];
#endif
}

- (IBAction) showOnlineHelp:sender
{
	NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBHelpURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showLicense:(id)sender
{
	[self.preferencesController selectControllerAtIndex:_licenseControllerIndex];
	[self.preferencesController showWindow:nil];
}

- (IBAction) showDiffToolPreferences:(id)sender
{
	[self.preferencesController selectControllerAtIndex:_diffToolsControllerIndex];
	[self.preferencesController showWindow:nil];
}

- (IBAction) releaseNotes:(id)sender
{
	NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GBReleaseNotesURL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction) showActivityWindow:(id)sender
{
	[[GBActivityController sharedActivityController] showWindow:sender];
}


- (void) updateAppleEvents
{
	NSString* GBCloneFromGithubKey = @"GBCloneFromGithub";
	NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:GBCloneFromGithubKey];
	if (!value) [[NSUserDefaults standardUserDefaults] setBool:YES forKey:GBCloneFromGithubKey];
	if (!value) value = [NSNumber numberWithBool:YES];

	//OSStatus status = 0;
	if ([value boolValue])
	{
		/*status =*/ LSSetDefaultHandlerForURLScheme((CFStringRef)@"github-mac", (__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	}
	else
	{
		/*status =*/ LSSetDefaultHandlerForURLScheme((CFStringRef)@"github-mac", (CFStringRef)@"com.github.GitHub");
		[[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
	}
}








#pragma mark - Application Delegate




- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
	[iRate sharedInstance].delegate = self;
	GBApp.didTerminateSafely = [[NSUserDefaults standardUserDefaults] boolForKey:@"GBDidTerminateSafely"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GBDidTerminateSafely"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[GBAskPassServer sharedServer]; // preload the server
    
	if (![[NSUserDefaults standardUserDefaults] objectForKey:kGBChangeDiffToolKey])
	{
		[[NSUserDefaults standardUserDefaults] setObject:[GBChange defaultDiffTool] forKey:kGBChangeDiffToolKey];
	}
	
#if !GITBOX_APP_STORE
	[SUUpdater sharedUpdater]; // preload updater
	
	#if DEBUG
		// Make beta builds update themselves regularly.
		[[SUUpdater sharedUpdater] resetUpdateCycle];
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
		[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:YES];
		[[SUUpdater sharedUpdater] setUpdateCheckInterval:12*60*60];
		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
		});
	#endif
#endif
	
#if DEBUG_iRate
#warning DEBUG: launching iRate dialog on start
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[iRate sharedInstance] promptForRating];
    });
#endif
	
	[self updateAppleEvents];
	
	[[GBActivityController sharedActivityController] loadWindow]; // force load the activity controller to begin monitoring the tasks
	
	self.rootController = [GBRootController new];
	id plist = [[NSUserDefaults standardUserDefaults] objectForKey:@"GBSidebarItems"];
	[self.rootController sidebarItemLoadContentsFromPropertyList:plist];
	[self.rootController addObserverForAllSelectors:self];
	
	self.windowController = [GBMainWindowController instance];
	
#if GITBOX_APP_STORE
	void(^removeMenuItem)(NSMenuItem*) = ^(NSMenuItem* item) {
		if (item) [[item menu] removeItem:item];
	};
	removeMenuItem(self.licenseMenuItem);
	removeMenuItem(self.checkForUpdatesMenuItem);
#endif
	
	self.licenseTextView.string = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GitboxLicense" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
	
#if GITBOX_APP_STORE
	NSArray* preferencesControllers = [NSArray arrayWithObjects:
									   [GBPreferencesDiffViewController controller],
									   [GBPreferencesConfigViewController controller],
									   nil];

#else
	NSArray* preferencesControllers = [NSArray arrayWithObjects:
									   [GBPreferencesDiffViewController controller],
									   [GBPreferencesConfigViewController controller],
									   [GBPreferencesUpdatesViewController controller],
									   [GBPreferencesLicenseViewController controller],
									   nil];
	_licenseControllerIndex = 3;
#endif
	
	_diffToolsControllerIndex = 0;
	
	self.preferencesController = [[MASPreferencesWindowController alloc] initWithViewControllers:preferencesControllers];
	
	self.windowController.rootController = self.rootController;
	[self.windowController showWindow:self];
	
	NSArray* urls = self.URLsToOpenAfterLaunch;
	self.URLsToOpenAfterLaunch = nil;
	[self.rootController openURLs:urls];
	
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeWasDisplayed"])
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeWasDisplayed"];
		[self.windowController showWelcomeWindow:self];
	}
	
	[GBOptimizeRepositoryController startMonitoring];
}

- (void) applicationWillTerminate:(NSNotification*)aNotification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveItems) object:nil];
	[self saveItems];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GBDidTerminateSafely"];
	[GBOptimizeRepositoryController stopMonitoring];
}


- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)aPath
{
	NSURL* aURL = [NSURL fileURLWithPath:aPath];
	if (!self.rootController) // not yet initialized
	{
		if (!self.URLsToOpenAfterLaunch) self.URLsToOpenAfterLaunch = [NSMutableArray array];
		[self.URLsToOpenAfterLaunch addObject:aURL];
		return YES;
	}
	return [self.rootController openURLs:[NSArray arrayWithObject:aURL]];
}

// Show the window if there's no key window at the moment. 
- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
#if !GITBOX_APP_STORE
#if DEBUG
	static NSTimeInterval lastCheckStamp = 0.0;
	
	if ([[NSDate date] timeIntervalSince1970] - lastCheckStamp > 3600)
	{
		lastCheckStamp = [[NSDate date] timeIntervalSince1970];
		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
		});
	}
#endif
#endif
	if (![NSApp keyWindow])
	{
		[self.windowController showWindow:self];
	}
}

// This method is called when Dock icon is clicked. This brings window to front if the app was active.
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
	[self.windowController showWindow:self];	
	return NO;
}

- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error
{
	if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSUserCancelledError) 
		return error;
	
	NSAlert* alert = [NSAlert alertWithError:error];
	
	[[GBMainWindowController instance] sheetQueueAddBlock:^{
		 // will be released in the callback
		[alert beginSheetModalForWindow:[[GBMainWindowController instance] window] 
						  modalDelegate:self
						 didEndSelector:@selector(presentedErrorAlertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}];

	NSLog(@"ERROR: %@", error);
	
	// Return "user cancelled" error because it's the only one which is not displayed.
	return [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
}

- (void) presentedErrorAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)ref
{
	[[alert window] orderOut:nil];
	[[GBMainWindowController instance] sheetQueueEndBlock];
	 // was retained in the application:willPresentError:
}





#pragma mark GBRootController notifications



- (void) rootControllerDidChangeContents:(GBRootController*)aRootController
{
	// Saves contents on the next cycle.
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveItems) object:nil];
	[self performSelector:@selector(saveItems) withObject:nil afterDelay:0.0];
}

- (void) rootControllerDidChangeSelection:(GBRootController*)aRootController
{
	// Saves contents a bit later
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveItems) object:nil];
	[self performSelector:@selector(saveItems) withObject:nil afterDelay:1.0];
}

- (void) saveItems
{
	if (!self.rootController) return;
	id plist = [self.rootController sidebarItemContentsPropertyList];
	[[NSUserDefaults standardUserDefaults] setObject:plist forKey:@"GBSidebarItems"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}





#pragma mark - Apple Events URL handling


- (void)handleUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	
	if ([urlString rangeOfString:@"github-mac://"].location == 0)
	{
		// Let the app start up if it was not launched.
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString* repoURLString = [urlString stringByReplacingOccurrencesOfString:@"github-mac://openRepo/" withString:@""];
			[self.rootController.repositoriesController cloneRepositoryAtURLString:repoURLString];
		});
	}
	else
	{
		NSLog(@"GBAppDelegate: unknown URL: %@", urlString);
	}
}


- (BOOL)iRateShouldPromptForRating
{
#if GITBOX_APP_STORE || DEBUG_iRate
	return YES;
#else
	return NO;
#endif
}




#pragma mark - Tests



- (void) simulateSetNeedsUpdate:(GBAsyncUpdater*)updater
{
	NSLog(@">> Setting setNeedsUpdate");
	[updater setNeedsUpdate];
	double delayInSeconds = 4.0*drand48();
	NSLog(@">> Will setNeedsUpdate after %f sec", delayInSeconds);
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self simulateSetNeedsUpdate:updater];
	});
	
//	if (drand48() > 0.0)
	{
		static int c = 0;
		static int uid = 0;
		uid += (int)(drand48()*10000);
		c++;
		int c_ = c;
		int uid_ = uid;
		NSLog(@">> Began waiting[%d]: c=%d ", uid_, c);
		[updater waitUpdate:^{
			c--;
			NSLog(@">> Ended waiting[%d]: c=%d [c was %d]", uid_, c, c_);
			if (c < 0)
			{
				NSLog(@"WARNING WARNING: imbalance detected! WARNING WARNING");
			}
		}];
	}
}

- (void) testGBAsyncUpdaterUpdate:(GBAsyncUpdater*)updater
{
	[updater beginUpdate];
	double delayInSeconds = 5.0*drand48();
	NSLog(@">> Began update for %f sec.", delayInSeconds);
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		[updater endUpdate];
		NSLog(@">> Update ended after %f sec.", delayInSeconds);
	});
}

- (void) testGBAsyncUpdater
{
	static GBAsyncUpdater* updater = nil;
	
	if (!updater)
	{
		updater = [GBAsyncUpdater updaterWithTarget:self action:@selector(testGBAsyncUpdaterUpdate:)];
	}
	
	[self simulateSetNeedsUpdate:updater];
}



- (void) testUTF8Healing
{
	srand(1);
	
	char bytes[] = {0xc0, 0x86};
	
	NSData* data = [NSData dataWithBytes:(void*)bytes length:2];
	NSLog(@"data = %@, string = %@ %@", data, [data UTF8String], [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	
	int failures = 10;
	while (1)
	{
		int length = rand() % 10 + 1;
		NSMutableData* data = [NSMutableData dataWithLength:length];
		unsigned char* bytes = (unsigned char*)[data mutableBytes];
		for (int i = 0; i < length; i++)
		{
			bytes[i] = (unsigned char)(((NSUInteger)rand()) % 256);
		}
		NSString* str = [data UTF8String];
		if (!str)
		{
			NSMutableString* hexString = [NSMutableString string];
			for (int i = 0; i < length; i++)
			{
				[hexString appendFormat:@"%x ", (unsigned)((unsigned char)(bytes[i]))];
			}      
			NSLog(@"FAILED to heal UTF-8 chars in %lu bytes: %@", [data length], hexString);
			
			// repeat one more time to enable breakpoints
			[data UTF8String];
			
			failures--;
			if (failures <= 0) {
				exit(1);
			}
		}
	}
}




//- (BOOL) checkGitVersion
//{
//  NSString* gitVersion = [GBRepository gitVersion];
//  if (!gitVersion)
//  {
//    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
//         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox requires git version %@ or later. Please install git or set its path in Preferences.", @"App"), 
//                      [GBRepository supportedGitVersion]]
//         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
//    [self.preferencesController showWindow:nil];
//    return NO;
//  }
//  else if (![GBRepository isSupportedGitVersion:gitVersion])
//  {
//    [NSAlert message:NSLocalizedString(@"Please locate git", @"App")
//         description:[NSString stringWithFormat:NSLocalizedString(@"The Gitbox works with the version %@ or later. Your git version is %@.\n\nPath to git executable: %@", @"App"), 
//                      [GBRepository supportedGitVersion], 
//                      gitVersion,
//                      [OATask systemPathForExecutable:@"git"]]
//         buttonTitle:NSLocalizedString(@"Open Preferences",@"App")];
//    [self.preferencesController showWindow:nil];
//    return NO;
//  }
//  return YES;
//}


@end
