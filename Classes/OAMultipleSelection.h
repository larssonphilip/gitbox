// Multiple selection resends action events to contained objects.
// Action is sent to every object which supports it unless one of them
// disables participation in multiple selection by returning NO from validateActionForMultipleSelection:(SEL)action
// If this method is not implemented, then action is considered validated for multiple selection.
@interface OAMultipleSelection : NSResponder

+ (OAMultipleSelection*) selectionWithObjects:(NSArray*)objects;

@end
