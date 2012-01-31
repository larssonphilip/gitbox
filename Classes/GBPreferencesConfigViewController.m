
#import "OATask.h"
#import "GBPreferencesConfigViewController.h"

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


- (IBAction)toggleMode:(id)sender
{
	[currentView removeFromSuperview];
	currentView = (currentView == basicView ? advancedView : basicView);
	currentView.frame = self.view.bounds;
	[self.view addSubview:currentView];
}

- (IBAction)nameOrEmailDidChange:(id)sender
{
	
}

- (void) textDidChange:(NSNotification*)notification
{
	
}

- (void) loadData
{
	static BOOL loading = NO;
	if (loading) return;
	
	// TODO: load ~/.gitconfig contents and name/email pair.
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
    return NSLocalizedString(@"Git Config", nil);
}

- (void)viewWillAppear
{
	[self loadData];
}

@end


