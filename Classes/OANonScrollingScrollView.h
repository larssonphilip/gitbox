// The purpose of this class to allow wheel-scrolling in some outer scroll view.
// Use case: a right panel scroll view with a autoresizeble textview, wrapped with its own scroll view.
// Without this class, if you try to scroll over the textview (which fits in its own scrollview), you won't scroll any view at all.
@interface OANonScrollingScrollView : NSScrollView
@end
