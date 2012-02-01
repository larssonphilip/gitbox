
#import "OATask.h"
#import "GBGitConfig.h"
#import "GBPreferencesConfigViewController.h"
#import "NSData+OADataHelpers.h"

@implementation GBPreferencesConfigViewController {
	NSView* currentView;
}
@synthesize basicView;
@synthesize advancedView;
@synthesize configTextView;
@synthesize nameTextField;
@synthesize emailTextField;

+ (GBPreferencesConfigViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesConfigViewController" bundle:nil] autorelease];
}


- (IBAction) toggleMode:(id)sender
{
	[currentView removeFromSuperview];
	currentView = (currentView == basicView ? advancedView : basicView);
	currentView.frame = self.view.bounds;
	[self.view addSubview:currentView];
}

- (IBAction) nameOrEmailDidChange:(id)sender
{
	
}

- (void) textDidChange:(NSNotification*)notification
{
	
}

- (void) loadData
{
	// Load ~/.gitconfig contents and name/email pair.
	
	id name = [[GBGitConfig userConfig] userName];
	id email = [[GBGitConfig userConfig] userEmail];
	
	[self.nameTextField setStringValue:name ? name : @""];
	[self.emailTextField setStringValue:email ? email : @""];
	
	NSData* configData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]]];
	NSString* configString = [configData UTF8String];
	
	[self.configTextView setString:configString ? configString : @""];
}

- (void) loadView
{
	[super loadView];
	
	if (!currentView) [self toggleMode:nil];
	
	[self loadData];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self.configTextView];
}


#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesConfig";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesConfig.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Git Settings", nil);
}

- (void)viewWillAppear
{
	[self loadData];
}

@end


