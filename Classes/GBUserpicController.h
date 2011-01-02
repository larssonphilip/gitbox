// This class manages loading and caching of the userpics fetched from various sources.
// Supported sources for now: address book, gravatar. More sources can be added if needed.

@interface GBUserpicController : NSObject

// Immediately returns image object or nil if not yet loaded.
- (NSImage*) imageForEmail:(NSString*)email;

// Fetches the image (from the cache, local storage or network) and calls the block when done.
- (void) loadImageForEmail:(NSString*)email withBlock:(void(^)())aBlock;

- (void) cancel;

- (void) removeCachedImages;

@end
