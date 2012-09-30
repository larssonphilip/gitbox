#import <Foundation/Foundation.h>

// State machine for a URL bookmark. Implements logic behind the UI of sidebar with repositories.
// Usage:
// 1. When adding new items use initWithURL:...
// 2. When loading items from persistent store use initWithBookmarkData:...
// 3. When getting FS events, use -check to silently check the status.
// 4. When user selects an item, call -resolve to mount external disks and authenticate if needed.

typedef enum : NSUInteger {
	// URL is resolved and available.
	GBURLBookmarkStatusAvailable,
	// URL is resolved, but it is in the trash. The app may throw away the bookmark for such URL.
	GBURLBookmarkStatusInTrash,
	// URL is resolved after calling -resolve method, but is missing (either the remote disk is unavailable, or the resource was removed).
	// E.g. the notebook is away from local fileserver. The app should not throw away the bookmark and not attempt to access the resource.
	GBURLBookmarkStatusUnavailableResolved,
	// Resource is unavailable after -check, but needs full resolution with possible mount of external disks performed by -resolve.
	// E.g. the user might need to mount the external drive and/or authenticate themselves.
	GBURLBookmarkStatusUnavailableNeedsResolution,
	// Status is set when URL is specified, but bookmark data cannot be created. See 'error' property.
	GBURLBookmarkStatusBookmarkCannotBeCreated,
} GBURLBookmarkStatus;

@interface GBURLBookmark : NSObject

- (id) initWithBookmarkData:(NSData*)data;
- (id) initWithBookmarkData:(NSData*)data withSecurityScope:(BOOL)withSecurityScope;
- (id) initWithURL:(NSURL*)URL;
- (id) initWithURL:(NSURL*)URL withSecurityScope:(BOOL)withSecurityScope;

// Status after the last call to -check or -resolve.
@property(nonatomic, readonly) GBURLBookmarkStatus status;

// Returns YES if it was set in the init* method.
@property(nonatomic, readonly) BOOL usesSecurityScope;

// Error or nil after the last -check or -resolve.
@property(nonatomic, readonly) NSError* error;

// When you set the URL, internal state is reset, bookmarkData is updated with the new URL.
@property(nonatomic) NSURL* URL;

// When you set the bookmark data, the internal state is reset and the URL is updated with -check call.
@property(nonatomic) NSData* bookmarkData;

// You should periodically check for the status using -check.
// This will not mount any external resources or present a system UI.
// This method updates status property and URL if possible.
- (void) check;

// When user selects an item, call -resolve to mount external disk if needed. This may present a system UI.
// This method updates status property.
- (void) resolve;

// Wraps block with start/stop messages below.
- (void) accessSecurityScopedResource:(void(^)())block;

// These do nothing if the URL was not resolved with security scope.
- (void) startAccessingSecurityScopedResource;
- (void) stopAccessingSecurityScopedResource;

@end
