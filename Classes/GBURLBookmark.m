#import "GBURLBookmark.h"

@interface GBURLBookmark ()
@property(nonatomic, readwrite) GBURLBookmarkStatus status;
@property(nonatomic, readwrite) BOOL usesSecurityScope;
@property(nonatomic, readwrite) NSError* error;
@property(nonatomic, readwrite, getter = isStale) BOOL stale;
@end

@implementation GBURLBookmark


#pragma mark - Initializers


- (id) initWithBookmarkData:(NSData*)data
{
	return [self initWithBookmarkData:data withSecurityScope:NO];
}

- (id) initWithBookmarkData:(NSData*)data withSecurityScope:(BOOL)withSecurityScope
{
	if (self = [super init])
	{
		self.usesSecurityScope = withSecurityScope;
		self.bookmarkData = data;
	}
	return self;
}

- (id) initWithURL:(NSURL*)URL
{
	return [self initWithURL:URL withSecurityScope:NO];
}

- (id) initWithURL:(NSURL*)URL withSecurityScope:(BOOL)withSecurityScope
{
	if (self = [super init])
	{
		self.usesSecurityScope = withSecurityScope;
		self.URL = URL;
	}
	return self;
}




#pragma mark - Properties




- (void) setURL:(NSURL *)URL
{
	if (_URL == URL) return;
	
	_URL = URL;
	_error = nil;
	
	if (_URL)
	{
		NSError* error = nil;
		_bookmarkData = [_URL bookmarkDataWithOptions:NSURLBookmarkCreationPreferFileIDResolution |
													(self.usesSecurityScope ? NSURLBookmarkCreationWithSecurityScope : 0)
					   includingResourceValuesForKeys:@[]
										relativeToURL:nil
												error:&error];
		if (!_bookmarkData)
		{
			_error = error;
			_status = GBURLBookmarkStatusBookmarkCannotBeCreated;
		}
		else
		{
			[self checkURL];
		}
	}
	else
	{
		_bookmarkData = nil;
		_status = GBURLBookmarkStatusUnavailableResolved;
	}
}

- (void) setBookmarkData:(NSData *)bookmarkData
{
	if (_bookmarkData == bookmarkData) return;
	
	_bookmarkData = bookmarkData;
	_error = nil;
	
	[self check];
}





#pragma mark - Accessing




- (NSString*) description
{
	NSString* statusString = nil;
	
	if (_status == GBURLBookmarkStatusAvailable) statusString = @"Available";
	if (_status == GBURLBookmarkStatusInTrash) statusString = @"InTrash";
	if (_status == GBURLBookmarkStatusUnavailableResolved) statusString = @"UnavailableResolved";
	if (_status == GBURLBookmarkStatusUnavailableNeedsResolution) statusString = @"NeedsResolution";
	if (_status == GBURLBookmarkStatusBookmarkCannotBeCreated) statusString = @"CannotBeCreated";
	
	return [NSString stringWithFormat:@"<%@:%p URL:%@ bookmark:%d status:%@ %@%@>",
			[self class], self, _URL, (int)_bookmarkData.length, statusString, _stale ? @"Stale " : @"", _error ?: @""];
}

- (void) check
{
	[self checkWithResolution:NO];
}

- (void) resolve
{
	[self checkWithResolution:YES];
}

- (void) accessSecurityScopedResource:(void(^)())block
{
	[self startAccessingSecurityScopedResource];
	if (block) block();
	[self stopAccessingSecurityScopedResource];
}

- (void) startAccessingSecurityScopedResource
{
	if (_usesSecurityScope) [self.URL startAccessingSecurityScopedResource];
}

- (void) stopAccessingSecurityScopedResource
{
	if (_usesSecurityScope) [self.URL stopAccessingSecurityScopedResource];
}




#pragma mark - Private



- (void) checkWithResolution:(BOOL)resolve
{
	if (_bookmarkData)
	{
		NSError* error = nil;
		BOOL isStale = NO;
		self.stale = NO;
		
		_URL = [NSURL URLByResolvingBookmarkData:_bookmarkData
										 options:(resolve ? 0 : (NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting)) |
				(self.usesSecurityScope ? NSURLBookmarkResolutionWithSecurityScope : 0)
								   relativeToURL:nil
							 bookmarkDataIsStale:&isStale
										   error:&error];
		
		if (!_URL)
		{
			_stale = isStale;
			_error = error;
			_status = (resolve ? GBURLBookmarkStatusUnavailableResolved : GBURLBookmarkStatusUnavailableNeedsResolution);
		}
		else
		{
			[self checkURL];
		}
	}
	else
	{
		_error = nil;
		_URL = nil;
		_status = GBURLBookmarkStatusUnavailableResolved;
	}
}

// Checks only given URL. Use this after resolving bookmark data or after the URL is explicitly set.
- (void) checkURL
{
	if (!_URL) @throw [NSException exceptionWithName:@"GBURLBookmarkInternalError" reason:@"URL cannot be nil in -checkURL" userInfo:nil];
	
	if ([[_URL absoluteString] rangeOfString:@"/.Trash/"].length > 0)
	{
		_status = GBURLBookmarkStatusInTrash;
	}
	else
	{
		_status = GBURLBookmarkStatusAvailable;
	}
}



@end
