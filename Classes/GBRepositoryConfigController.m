#import "GBRepository.h"
#import "GBRepositoryConfigController.h"

@interface GBRepositoryConfigController ()
@property (nonatomic,copy) NSString* contents;
@end

@implementation GBRepositoryConfigController

@synthesize textView;
@synthesize contents;

- (void) dealloc
{
	self.contents = nil;
	[super dealloc];
}

- (id) initWithRepository:(GBRepository *)repo
{
	if ((self = [super initWithRepository:repo]))
	{
	}
	return self;
}

- (NSString*) title
{
	return NSLocalizedString(@"Advanced", @"");
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	NSError* error = nil;
	self.contents = [NSString stringWithContentsOfFile:[self.repository.path stringByAppendingPathComponent:@".git/config"] encoding:NSUTF8StringEncoding error:&error];
	
	if (!self.contents)
	{
		NSLog(@"GBRepositoryConfigController: Error while reading .git/config: %@", error);
	}
	else
	{
		[self.textView setString:[[self.contents copy] autorelease]];
	}
}

- (void) save
{
	NSError* error = nil;
	NSString* config = [[self.textView.string copy] autorelease];
	
	// Check if we have really changed contents. Otherwise we may overwrite update from the "Remotes" tab.
	if (config && self.contents && [self.contents isEqual:config])
	{
		return;
	}
	
	if (![config writeToFile:[self.repository.path stringByAppendingPathComponent:@".git/config"] 
					 atomically:YES 
					   encoding:NSUTF8StringEncoding 
						  error:&error])
	{
		NSLog(@"Error: .git/config update failed: %@", error);
	}
}


@end
