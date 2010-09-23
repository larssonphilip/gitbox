
#define OAOptionalDelegateMessage(selector) \
          if ([delegate respondsToSelector:@selector(selector)]) \
          { [delegate selector self]; }
