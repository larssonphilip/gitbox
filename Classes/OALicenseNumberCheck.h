#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

/*
 def genpartialchecksum(prefix, key, hexsize)
	Digest::MD5.hexdigest(prefix + key)[0, hexsize].rjust(hexsize, '0')
 end
 
 # this allows to check only a subset of keys to be able to grow further
 def checkserial(serial, n, m, keys, hexsize)
	 required_size = n + m*hexsize
	 serial.size == required_size or return false
	 prefix = serial[0,n]
	 fullchecksum = serial[n, required_size - n]
	 partialchecksums = fullchecksum.scan(/.{#{hexsize}}/)
	 keys.each do |key|
		partialchecksum = partialchecksums.shift
		partialchecksum == genpartialchecksum(prefix, key, hexsize) or return false
	 end
	 return true
 end

 
 */

static inline BOOL OAValidateLicenseNumber(NSString* licenseNumber)
{
	if (!licenseNumber) return NO;
	
	NSUInteger N = 12;
	NSUInteger M = 8;
	NSUInteger H = 4;
	
	NSUInteger requiredSize = N + M*H;
	
	if ([licenseNumber length] != requiredSize) return NO;
	
	NSString* prefix = [licenseNumber substringToIndex:N];
	NSString* fullchecksum = [licenseNumber substringFromIndex:N];
	
	NSUInteger offset = 0;
	NSString* checksum1 = [fullchecksum substringWithRange:NSMakeRange(offset, H)];
	offset += H;
	
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
	 2tb8e1irclkbhrsjsdne80kic6j513tdgh2ivuff012mstc544
	 1fahqgk8mebj78i9srvdlje5jrhbrmn5p166kcu474q83ausr4
	 plcmac8idko953ntbvsiun8u4cff3k5nf7nv7kr40vnt5g21ee
	 lbq8o711gesd0s5b1m8g1o919cvfvrt7igjb05lvlkvn220v3g
	 1ej44ifp9i1rsl5g8u11oh2rs54emupvfl0cgmgu5g9it91t3h
	 17pgkrckcvd80rumvi5vbji6p8gmbth0hi1h1gmsv8hevc6fd8
	 ig6dsbuvmg2gubu0e35bbrj95nd8sek7t3vp8o3varucgktcno
	 1rjjdnjmv6gaefdocq20if3avrovdv92lheoaairmkviven63t
	 */
	NSString* key1 = [NSString stringWithFormat:@"2tb8e1irclkbhrsjsdne80k%@", @"ic6j513tdgh2ivuff012mstc"];
	
	if (![checksum1 isEqualToString:partialChecksum(prefix, [key1 stringByAppendingFormat:@"%d", 544], H)]) return NO;
	
	// TODO: add more keys later
	
	return YES;
}


