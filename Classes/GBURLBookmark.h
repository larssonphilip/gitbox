#import <Foundation/Foundation.h>

// State machine for a URL bookmark. Implements logic behind the UI of sidebar with repositories.
// Usage:
// 1. When adding new items use initWithURL:...
// 2. When loading items from persistent store use initWithBookmarkData:...
// 3. When getting FS events, use -check to silently check the status.

typedef enum : NSUInteger {
	GBURLBookmarkStatusAvailable,
	GBURLBookmarkStatusInTrash,
	GBURLBookmarkStatusUnavailable,
} GBURLBookmarkStatus;

@interface GBURLBookmark : NSObject

- (id) initWithBookmarkData:(NSData*)data;
- (id) initWithBookmarkData:(NSData*)data withSecurityScope:(BOOL)withSecurityScope;
- (id) initWithURL:(NSURL*)URL;
- (id) initWithURL:(NSURL*)URL withSecurityScope:(BOOL)withSecurityScope;

@property(readonly) GBURLBookmarkStatus status;

// 
@property(readonly) BOOL usesSecurityScope;

// When you set the URL, internal state is reset, bookmarkData is updated with the new URL.
@property NSURL* URL;

@property NSData* bookmarkData;

// You should periodically check for the status using -check.
// This will not mount any external resources or present a system UI.
// This method updates status property.
- (void) check;

// When user selects an item, call -resolve to mount external disk if needed. This may present a system UI.
// This method updates status property.
- (void) resolve;

@end
