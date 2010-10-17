
#define GBNotificationDeclare(NAME) extern NSString* const NAME;
#define GBNotificationDefine(NAME) NSString* const NAME = @#NAME;
#define GBNotificationSend(NAME) [[NSNotificationCenter defaultCenter] postNotificationName:NAME object:self]
