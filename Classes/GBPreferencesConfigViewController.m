
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

- (NSURL*) configURL
{
	return [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
}

- (void) loadConfigData
{
	NSData* configData = [NSData dataWithContentsOfURL:[self configURL]];
	NSString* configString = [configData UTF8String];
	
	[self.configTextView setString:configString ? configString : @""];
}

- (void) loadBasicData
{
	id name = [[GBGitConfig userConfig] userName];
	id email = [[GBGitConfig userConfig] userEmail];
	
	[self.nameTextField setStringValue:name ? name : @""];
	[self.emailTextField setStringValue:email ? email : @""];
}


- (void) loadData
{
	[self loadBasicData];
	[self loadConfigData];
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
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 1.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		if (c != counter) return;
		[[GBGitConfig userConfig] setName:self.nameTextField.stringValue 
									email:self.emailTextField.stringValue 
								withBlock:^{
									[self loadConfigData];
		}];
	});
}

- (void) textDidChange:(NSNotification*)notification
{
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 1.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		if (c != counter) return;
		[[self.configTextView.string dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[self configURL] atomically:YES];
		[self loadBasicData];
	});
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


