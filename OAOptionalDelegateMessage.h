
#define OAOptionalDelegateMessage(selector) \
          if ([delegate respondsToSelector:selector]) { \
            [delegate performSelector:selector withObject:self]; \
          }
