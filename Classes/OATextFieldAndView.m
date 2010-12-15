#import "OATextFieldAndView.h"

@implementation OATextField

- (BOOL)becomeFirstResponder
{
  BOOL r = [super becomeFirstResponder];
  if ([self.delegate respondsToSelector:@selector(textField:willBecomeFirstResponder:)])
  {
    [(id<OATextFieldDelegate>)self.delegate textField:self willBecomeFirstResponder:r];
  }
  return r;
}

// This is called immediately after [suepr becomeFirstResponder] because textfield delegates editing to fild editor (NSText)
//- (BOOL)resignFirstResponder
//{
//  BOOL r = [super resignFirstResponder];
//  if ([self.delegate respondsToSelector:@selector(textField:willResignFirstResponder:)])
//  {
//    [(id<OATextFieldDelegate>)self.delegate textField:self willResignFirstResponder:r];
//  }
//  return r;
//}

- (IBAction) cancel:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(textField:didCancel:)])
  {
    [(id<OATextFieldDelegate>)self.delegate textField:self didCancel:sender];
  }
}

@end



@implementation OATextView

- (BOOL)becomeFirstResponder
{
  BOOL r = [super becomeFirstResponder];
  if ([self.delegate respondsToSelector:@selector(textView:willBecomeFirstResponder:)])
  {
    [(id<OATextViewDelegate>)self.delegate textView:self willBecomeFirstResponder:r];
  }
  return r;
}

- (BOOL)resignFirstResponder
{
  BOOL r = [super resignFirstResponder];
  if ([self.delegate respondsToSelector:@selector(textView:willResignFirstResponder:)])
  {
    [(id<OATextViewDelegate>)self.delegate textView:self willResignFirstResponder:r];
  }
  return r;
}

- (IBAction) cancel:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(textView:didCancel:)])
  {
    [(id<OATextViewDelegate>)self.delegate textView:self didCancel:sender];
  }
}

@end
