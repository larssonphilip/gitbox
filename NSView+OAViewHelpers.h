@interface NSView (OAViewHelpers)

- (NSView*) removeAllSubviews; 
- (NSView*) setViewController:(NSViewController*)aViewController;

@end


@interface NSViewController (OAViewHelpers)

- (void) viewDidUnload;
- (void) unloadView;

@end