#import "GitConfig.h"
#import <git2.h>

@interface GitConfig ()
@property(nonatomic,assign) git_config* config;
@end

@implementation GitConfig

@synthesize config;

- (id) initWithRepositoryURL:(NSURL*)repoURL
{
    if ((self = [self init]))
	{
		NSString* path = [repoURL.absoluteString stringByAppendingPathComponent:@".git/config"];
		git_error error = git_config_open_ondisk(&config, [path cStringUsingEncoding:NSUTF8StringEncoding]);
		
		if (error != GIT_SUCCESS)
		{
			NSLog(@"GitConfig error while opening %@: %d", path, error);
			[self release];
			return nil;
		}
    }
    return self;
}

- (id) initGlobalConfig
{
    if ((self = [self init]))
	{
		git_error error = git_config_open_global(&config);
		
		if (error != GIT_SUCCESS)
		{
			#warning TODO: Check if ~/.gitconfig file exists. If it doesn't, create one and retry.
			
			NSLog(@"GitConfig error while opening global config: %d", error);
			[self release];
			return nil;
		}
    }
    return self;	
}

- (void) close
{
	if (config) git_config_free(config);
	config = NULL;
}

- (void)dealloc
{
	if (config) git_config_free(config);
	config = NULL;
	
    [super dealloc];
}

@end
