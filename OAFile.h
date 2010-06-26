//
// Collection of routines for simple data retrieval and storage for different kinds of data.
//

@interface OAFile : NSObject


#pragma mark Read

+ (NSData*) dataForPath:(NSString*)path;

+ (id) propertyListForPath:(NSString*)path mutabilityOption:(NSPropertyListMutabilityOptions)opt;
+ (id) immutablePropertyListForPath:(NSString*)path;
+ (id) mutablePropertyListForPath:(NSString*)path;

+ (NSString*) stringForPath:(NSString*)path encoding:(NSStringEncoding)encoding;
+ (NSString*) utf8StringForPath:(NSString*)path;

+ (BOOL) isReadable:(NSString*)path;


#pragma mark Write

+ (id) createFolderForPath:(NSString*)path;
+ (id) createFolderForFilePath:(NSString*)path;

+ (id) setData:(NSData*)data forPath:(NSString*)path;
+ (id) setPropertyList:(id)plist forPath:(NSString*)path;

+ (id) setString:(NSString*) string withEncoding:(NSStringEncoding)encoding forPath: (NSString*) path;
+ (id) setUtf8String:(NSString*) string forPath: (NSString*) path;


#pragma mark Delete

// this handles non-empty folders as well
+ (id) removeFileAtPath:(NSString*)path;


#pragma mark Conversion Helpers

+ (NSData*) dataFromPropertyList:(id) plist;
+ (id) propertyListFromData:(NSData*)data mutabilityOption:(NSPropertyListMutabilityOptions)opt;
+ (id) immutablePropertyListFromData:(NSData*)data;
+ (id) mutablePropertyListFromData:(NSData*)data;


@end
