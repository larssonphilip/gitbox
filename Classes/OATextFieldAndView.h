

@protocol OATextFieldDelegate<NSObject,NSTextFieldDelegate>
- (void) textField:(NSTextField*)aTextField willBecomeFirstResponder:(BOOL)result;
- (void) textField:(NSTextField*)aTextField didCancel:(id)sender;
@end


@protocol OATextViewDelegate<NSObject,NSTextViewDelegate>
- (void) textView:(NSTextView*)aTextView willBecomeFirstResponder:(BOOL)result;
- (void) textView:(NSTextView*)aTextView willResignFirstResponder:(BOOL)result;
- (void) textView:(NSTextView*)aTextView didCancel:(id)sender;
@end


@interface OATextField : NSTextField
@end


@interface OATextView : NSTextView
@end

