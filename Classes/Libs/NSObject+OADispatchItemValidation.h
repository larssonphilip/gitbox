
@interface NSObject (OADispatchItemValidation)

// For anItem.action == @selector(playGuitar:) this method will try to call a method validatePlayGuitar:(id)sender
// Returns YES if the specialized method does not exist.
// Returns NO if the item's action is nil.

// Example: 
//  - (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
//  {
//    return [self dispatchUserInterfaceItemValidation:anItem];
//  }

- (BOOL) dispatchUserInterfaceItemValidation:(id<NSValidatedUserInterfaceItem>)anItem;

@end
