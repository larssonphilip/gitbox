#import "GBTask.h"
#import "GBSubmoduleInitTask.h"


@implementation GBSubmoduleInitTask

@synthesize targetURL;

- (void) dealloc
{
	self.targetURL = nil;
	[super dealloc];
}

- (NSString*) launchPath
{
	return [GBTask pathToBundledBinary:@"git"];
}

- (void) prepareTask
{	
	self.currentDirectoryPath = [self.targetURL path];
	self.arguments = [NSArray arrayWithObjects:@"submodule", @"init", nil];

	[super prepareTask];
}

@end
