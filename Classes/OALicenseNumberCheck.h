#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

NS_INLINE BOOL OAValidateLicenseNumber(NSString* licenseNumber)
{
	if (!licenseNumber) return NO;
	
  licenseNumber = [licenseNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
	NSUInteger N = 12;
	NSUInteger M = 8;
	NSUInteger H = 4;
	
	NSUInteger requiredSize = N + M*H;
	
	if ([licenseNumber length] != requiredSize) return NO;
		
	NSString* (^partialChecksum)(NSString*, NSString*, NSUInteger) = ^(NSString* prefix, NSString* key, NSUInteger hexsize) {
		NSString*(^md5HexDigest)(NSString*) = NULL;
		md5HexDigest = ^(NSString* input) {
			const char* str = [input UTF8String];
			unsigned char result[CC_MD5_DIGEST_LENGTH];
			CC_MD5(str, strlen(str), result);
			
			return [NSString stringWithFormat:
					@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
					result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
					result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
					];
		};
		return [md5HexDigest([prefix stringByAppendingString:key]) substringToIndex:hexsize];
	};
	
	
	/*
   534271628253969666149
   53868794303198114726
   9491754476354925543641310243
   3501320648431136786206865455
   72578056688
   18797547350062531
   732462
   745543651098770262381351052
	 */
  
  NSString* prefix = licenseNumber;
  NSUInteger offset = requiredSize;
  
  offset = requiredSize - H;
  prefix = [licenseNumber substringToIndex:offset];
	NSString* c8 = [licenseNumber substringFromIndex:offset]; 
	NSString* key8 = [NSString stringWithFormat:@"%@%d%@", @"745543651", 0, @"9877026238135105"];
	
	if (![c8 isEqualToString:partialChecksum(prefix, [key8 stringByAppendingFormat:@"%d", 2], H)]) return NO;
	
	// TODO: add more keys later
	
  
	return YES;
}

