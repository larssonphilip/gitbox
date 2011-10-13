#import "GitRepository.h"
#import "GitConfig.h"
#import <git2.h>

@interface GitRepository ()
@property(nonatomic, assign) git_repository* repository;
- (void) reloadRepository;
@end

@implementation GitRepository

@synthesize URL;
@synthesize repository;

+ (GitRepository*) repositoryWithURL:(NSURL*)URL
{
	GitRepository* repo = [[[self alloc] init] autorelease];
	repo.URL = URL;
	return repo;
}

- (id)init
{
    if ((self = [super init]))
	{
    }
    return self;
}

- (void)dealloc
{
	self.repository = NULL;
	[URL release]; URL = nil;
    [super dealloc];
}

- (void) setURL:(NSURL *)newURL
{
	if (URL == newURL || (URL && newURL && [URL isEqual:newURL])) return;
	
	[URL release];
	URL = [newURL retain];
	
	[self reloadRepository];
}

- (void) setRepository:(git_repository *)newrepository
{
	if (newrepository == repository) return;
	
	if (repository) git_repository_free(repository);
	repository = newrepository;
}

- (void) reloadRepository
{
	if (!URL)
	{
		self.repository = NULL;
		return;
	}
	git_repository* repo = NULL;
		
	NSString* path = URL.absoluteURL.path;
	
	BOOL isBare = NO; // TODO: check if the repo is bare or contains working files
	if (!isBare)
	{
		path = [path stringByAppendingPathComponent:@".git"];
	}
	
	if (!git_repository_open(&repo, [path cStringUsingEncoding:NSUTF8StringEncoding]))
	{
		self.repository = repo;
	}
	else
	{
		NSLog(@"GitRepository error occured: %s (self.URL = %@)", git_lasterror(), self.URL);
		self.repository = nil;
	}
}

- (GitConfig*) config
{
	return [[[GitConfig alloc] initWithRepositoryURL:self.URL] autorelease];
}

- (NSString*) commitIdForRefName:(NSString*)refName
{
	if (!refName) return nil;
	
	git_reference* ref = NULL;
	if (GIT_SUCCESS == git_reference_lookup(&ref, self.repository, [refName cStringUsingEncoding:NSUTF8StringEncoding]))
	{
		git_reference* resolvedRef = NULL;
		if (GIT_SUCCESS == git_reference_resolve(&resolvedRef, ref))
		{
			const git_oid* oid = git_reference_oid(resolvedRef);
			if (oid)
			{
				char out[41];
				git_oid_fmt(out, oid);
				out[40] = '\0';
				return [NSString stringWithCString:out encoding:NSUTF8StringEncoding];
			}
		}
	}
	return nil;
}

@end
