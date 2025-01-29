#import "GitConfig.h"
#import <git2.h>

@interface GitConfig ()
@property(nonatomic,assign) git_config* config;
@end

@implementation GitConfig

@synthesize config;

- (NSURL*) userConfigURL
{
	return [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@".gitconfig"]];
}

- (id) initGlobalConfig
{
    if ((self = [self init]))
	{
		// TODO: not tested, not used yet.
		if (![[NSFileManager new] fileExistsAtPath:self.userConfigURL.path])
		{
			//[[NSData data] writeToFile:self.userConfigURL.path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
            [[NSData data] writeToFile:self.userConfigURL.path options:NSDataWritingAtomic error:nil];
		}
		
		git_error error = git_config_open_global(&config);
		
		//NSLog(@"GitConfig initGlobalConfig: %p [%d, %s]", config, error, git_lasterror());
		if (error != GIT_SUCCESS)
		{
			config = NULL;
			NSLog(@"GitConfig error while opening global config: %d [%s]", error, git_lasterror());
			return nil;
		}
    }
    return self;	
}

- (id) initWithRepositoryURL:(NSURL*)repoURL
{
    if ((self = [self init]))
	{
		NSString* path = [repoURL.path stringByAppendingPathComponent:@".git/config"];
		git_error error = git_config_open_ondisk(&config, [path cStringUsingEncoding:NSUTF8StringEncoding]);
		
		//NSLog(@"GitConfig initWithRepositoryURL: %p [%d, %s] (%@)", config, error, git_lasterror(), path);
		
		if (error != GIT_SUCCESS)
		{
			NSLog(@"GitConfig error while opening %@: %d [%s]", path, error, git_lasterror());
			config = NULL;
			return nil;
		}
    }
    return self;
}

- (id) initWithURL:(NSURL*)configURL
{
    if ((self = [self init]))
	{
		NSString* path = configURL.path;
		git_error error = git_config_open_ondisk(&config, [path cStringUsingEncoding:NSUTF8StringEncoding]);
		
		//NSLog(@"GitConfig initWithURL: %p [%d, %s] (%@)", config, error, git_lasterror(), path);
		
		if (error != GIT_SUCCESS)
		{
			NSLog(@"GitConfig error while opening %@: %d [%s]", path, error, git_lasterror());
			config = NULL;
			return nil;
		}
    }
    return self;	
}

- (void) close
{
	//NSLog(@"GitConfig close: %p", config);
	if (config) git_config_free(config);
	config = NULL;
}

- (void)dealloc
{
	//NSLog(@"GitConfig dealloc: %p", config);
	if (config) git_config_free(config);
	config = NULL;
	
}




#pragma mark Access Methods



- (NSString*) stringForKey:(NSString*)key
{
	if (!config) return nil;
	
	const char *result = NULL;
	if (GIT_SUCCESS == git_config_get_string(config, [key cStringUsingEncoding:NSUTF8StringEncoding], &result))
	{
		if (!result) return nil;
		return [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
	}
	return nil;
}

- (void) setString:(NSString*)string forKey:(NSString*)key
{
	git_error error = git_config_set_string(config, [key cStringUsingEncoding:NSUTF8StringEncoding], [string cStringUsingEncoding:NSUTF8StringEncoding]);
	if (error != GIT_SUCCESS)
	{
		NSLog(@"GitConfig error when setting a key %@ with value %@ [%s]", key, string, git_lasterror());
	}
}

- (void) removeKey:(NSString*)key
{
	git_error error = git_config_delete(config, [key cStringUsingEncoding:NSUTF8StringEncoding]);
	if (error != GIT_SUCCESS)
	{
		NSLog(@"GitConfig error when deleting a key %@ [%s]", key, git_lasterror());
	}
}


//
// * Perform an operation on each config variable.
// *
// * The callback receives the normalized name and value of each variable
// * in the config backend, and the data pointer passed to this function.
// * As soon as one of the callback functions returns something other than 0,
// * this function returns that value.
// *
// * @param cfg where to get the variables from
// * @param callback the function to call on each variable
// * @param payload the data to pass to the callback
// * @return GIT_SUCCESS or the return value of the callback which didn't return 0
//
//GIT_EXTERN(int) git_config_foreach(
//								   git_config *cfg,
//								   int (*callback)(const char *var_name, const char *value, void *payload),
//								   void *payload);

int GitConfigEnumerationFunction(const char *key, const char *value, void *payload)
{
	void (^block)(id key, id obj, BOOL *stop) = (__bridge void (^)(id, id, BOOL*))payload;
	BOOL stop = NO;
	block([NSString stringWithCString:key encoding:NSUTF8StringEncoding], 
		  [NSString stringWithCString:value encoding:NSUTF8StringEncoding], 
		  &stop);
	if (stop) return 1;
	return 0;
}

- (void) enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
	if (!block) return;
	git_config_foreach(config, GitConfigEnumerationFunction, (__bridge void*)block);
}

@end
