
@interface NSObject (OADispatchItemValidation)

// For anItem.action == @selector(playGuitar:) this method will try to call method validatePlayGuitar:(id)sender
// Returns YES if specialized method does not exist.
// Returns NO if item's action is nil.

// Example: 
//  - (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
//  {
//    return [self dispatchUserInterfaceItemValidation:anItem];
//  }

- (BOOL) dispatchUserInterfaceItemValidation:(id<NSValidatedUserInterfaceItem>)anItem;

@end
