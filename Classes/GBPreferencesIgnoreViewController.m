#import "GBGitConfig.h"
#import "GBPreferencesIgnoreViewController.h"
#import "NSData+OADataHelpers.h"

@interface GBPreferencesIgnoreViewController ()
@property(nonatomic, copy) NSString* labelString;
@end

@implementation GBPreferencesIgnoreViewController
@synthesize labelString;
@synthesize textView;
@synthesize label;

- (void)dealloc
{
    [label release];
    [super dealloc];
}

+ (GBPreferencesIgnoreViewController*) controller
{
	return [[[self alloc] initWithNibName:@"GBPreferencesIgnoreViewController" bundle:nil] autorelease];
}

- (NSURL*) fileURL
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

- (void) loadData
{
	NSURL* url = [self fileURL];
	if (!url)
	{
		NSLog(@"ERROR: Cannot get url for gitignore file!");
		return;
	}
	NSData* data = [NSData dataWithContentsOfURL:url];
	NSString* string = [data UTF8String];
	
	[self.textView setString:string ? string : @""];
	
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

- (void) textDidChange:(NSNotification*)notification
{
	static int counter = 0;
	counter++;
	int c = counter;
	double delayInSeconds = 1.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		if (c != counter) return;
		[[self.textView.string dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[self fileURL] atomically:YES];
	});
}

- (void) loadView
{
	[super loadView];
	
	self.labelString = self.label.stringValue;
	[self loadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self.textView];
}



#pragma mark - MASPreferencesViewController


- (NSString *)identifier
{
    return @"GBPreferencesIgnore";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"GBPreferencesIgnore.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Ignored Files", nil);
}

- (void)viewWillAppear
{
	[self loadData];
}

@end


