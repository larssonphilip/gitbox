#import "OAAreEqual.h"

// Returns YES if both are nil or [a isEqual:b] returns YES.
BOOL OAAreEqual(id a, id b)
{
	if (!a && !b) return YES;
	return [a isEqual:b];
}
