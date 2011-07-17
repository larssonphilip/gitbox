#import "GitRepository.h"
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
	if (!git_repository_open(&repo, [[[URL absoluteURL] path] cStringUsingEncoding:NSUTF8StringEncoding]))
	{
		self.repository = repo;
	}
	else
	{
		NSLog(@"GitRepository error occured: %s (self.URL = %@)", git_lasterror(), self.URL);
		self.repository = nil;
	}
}

@end
