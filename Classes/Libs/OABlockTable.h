#import <Foundation/Foundation.h>

// Manages a table of blocks by name. Concatenates blocks with the same name when added. Clears a block when it is called.

@interface OABlockTable : NSObject

// Returns YES if there's block in the table for the given name.
- (BOOL) containsBlockForName:(NSString*)aName;

// Concatenates block with existing block for the given name.
- (void) addBlock:(void(^)())aBlock forName:(NSString*)aName;

// Clears block for the name and calls it.
- (void) callBlockForName:(NSString*)aName;

// Adds block for the name and calls continuation if the name was clear.
- (void) addBlock:(void(^)())aBlock forName:(NSString*)aName andProceedIfClear:(void(^)())continuation;

@end
