
#import "OATask.h"
#import "GBGitConfig.h"
#import "GBPreferencesConfigViewController.h"
#import "NSData+OADataHelpers.h"

@interface GBPreferencesConfigViewController ()
@property(nonatomic, copy) NSString* labelString;
@end

@implementation GBPreferencesConfigViewController {
	NSView* currentView;
}
@synthesize basicView;
@synthesize advancedView;
@synthesize configTextView;
@synthesize ignoreTextView;
@synthesize nameTextField;
@synthesize emailTextField;
@synthesize label;
@synthesize labelString;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [labelString release];
    [super dealloc];
}

+ (GBPreferencesConfigViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesConfigViewController" bundle:nil] autorelease];
}

- (NSURL*) configURL
{
	return [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
}

- (NSURL*) gitignoreURL
{
	NSString* path = [[GBGitConfig userConfig] stringForKey:@"core.excludesfile"];
	
	if (path.length == 0)
	{
		path = [NSHomeDirectory() stringByAppendingPathComponent:@".gitignore"];
		[[GBGitConfig userConfig] setString:path forKey:@"core.excludesfile"];
	}
	
	path = [path stringByExpandingTildeInPath];
	
	if (path.length > 0 && [path characterAtIndex:0] != [@"/" characterAtIndex:0])
	{
		path = [NSHomeDirectory() stringByAppendingPathComponent:path];
	}
	return [NSURL fileURLWithPath:path];
}

- (void) loadIgnoreData
{
	NSURL* url = [self gitignoreURL];
	if (!url)
	{
		NSLog(@"ERROR: Cannot get url for gitignore file!");
		return;
	}
	NSData* data = [NSData dataWithContentsOfURL:url];
	
	if (!data)
	{
		[[@".DS_Store\n" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:url atomically:YES];
		data = [NSData dataWithContentsOfURL:url];
	}
	
	NSString* string = [data UTF8String];
	
	[self.ignoreTextView setString:string ? string : @""];
	
	NSString* path = [url path];
	
	if ([path rangeOfString:NSHomeDirectory()].length > 0)
	{
		path = [path stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
		self.label.stringValue = self.labelString ? [self.labelString stringByReplacingOccurrencesOfString:@".gitignore" withString:path] : path;
	}
	else
	{
		self.label.stringValue = [NSString stringWithFormat:NSLocalizedString(@"These settings are stored in %@.", @""), path];
	}
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
	[self loadIgnoreData];
	[self loadConfigData];
}


- (IBAction) toggleMode:(id)sender
{
	[currentView removeFromSuperview];
	currentView = (currentView == basicView ? advancedView : basicView);
	currentView.frame = self.view.bounds;
	[self.view addSubview:currentView];
}

- (IBAction) nameOrEmailDidChange:(id)senderOrNotification
{
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 0.5;
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

- (void) configTextDidChange:(NSNotification*)notification
{
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 0.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		if (c != counter) return;
		[[self.configTextView.string dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[self configURL] atomically:YES];
		[self loadBasicData];
	});
}

- (void) ignoreTextDidChange:(NSNotification*)notification
{
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 0.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		if (c != counter) return;
		[[self.ignoreTextView.string dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[self gitignoreURL] atomically:YES];
	});
}

- (void) loadView
{
	[super loadView];
	
	self.labelString = self.label.stringValue;
	
	if (!currentView) [self toggleMode:nil];
	
	[self loadData];
	
	if (self.configTextView) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configTextDidChange:) name:NSTextDidChangeNotification object:self.configTextView];
	if (self.ignoreTextView) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ignoreTextDidChange:) name:NSTextDidChangeNotification object:self.ignoreTextView];

	if (self.nameTextField)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nameOrEmailDidChange:) name:NSControlTextDidChangeNotification object:self.nameTextField];
	if (self.emailTextField)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nameOrEmailDidChange:) name:NSControlTextDidChangeNotification object:self.emailTextField];
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


