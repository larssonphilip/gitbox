#import <Foundation/Foundation.h>

extern NSString* const GBAskPassServerNameKey;
extern NSString* const GBAskPassClientIdKey;

// Protocol is declared for use in the remote process.
@protocol GBAskPassServer <NSObject>
- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment;
- (NSString*) echo:(NSString*)string;
@end

// A local client object which responds to the queries.
@protocol GBAskPassServerClient <NSObject>
@required
- (NSString*) askPassClientId;
- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment;
@end



@interface GBAskPassServer : NSObject<GBAskPassServer>

@property(nonatomic, copy, readonly) NSString* name;

+ (GBAskPassServer*) sharedServer; // API for serving process
+ (NSDistantObject<GBAskPassServer>*) remoteServerWithName:(NSString*)aName;

- (void) invalidate;

- (void) addClient:(id<GBAskPassServerClient>)aClient;
- (void) removeClient:(id<GBAskPassServerClient>)aClient;

- (void) setResult:(NSString*)aResult forClientId:(NSString*) aClientId;

@end
