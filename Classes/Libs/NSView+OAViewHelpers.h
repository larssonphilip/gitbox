@interface NSView (OAViewHelpers)

- (NSView*) removeAllSubviews; 

@end


@interface NSViewController (OAViewHelpers)

- (void) unloadView;
- (id) loadInView:(NSView*) targetView;

@end