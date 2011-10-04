#import <AddressBook/AddressBook.h>
#import "GBUserpicController.h"
#import "OAHTTPDownload.h"
#import "OAHTTPQueue.h"
#import "NSString+OAStringHelpers.h"

@interface GBUserpicController ()
@property(nonatomic,retain) NSCache* cache;
@property(nonatomic,retain) OAHTTPQueue* httpQueue;
@end

@implementation GBUserpicController

@synthesize cache;
@synthesize httpQueue;

- (void) dealloc
{
	self.cache = nil;
	[self.httpQueue cancel];
	self.httpQueue = nil;
	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.cache = [[[NSCache alloc] init] autorelease];
		[self.cache setTotalCostLimit:10*1024*1024];
		[self.cache setCountLimit:1000];
		
		self.httpQueue = [[OAHTTPQueue new] autorelease];
		self.httpQueue.coalesceURLs = YES;
		self.httpQueue.maxConcurrentOperationCount = 6;
		self.httpQueue.limit = 12.0;
	}
	return self;
}

// Immediately returns image object or nil if not yet loaded.
- (NSImage*) imageForEmail:(NSString*)email
{
	if (!email) return nil;
	return [self.cache objectForKey:email];
}

// Fetches the image (from the cache, local storage or network) and calls the block when done.
- (void) loadImageForEmail:(NSString*)email withBlock:(void(^)())aBlock
{
	aBlock = [[aBlock copy] autorelease];
	if (!email || [self.cache objectForKey:email])
	{
		if (aBlock) aBlock();
		return;
	}
	
	// 1. Local AddressBook entry
	
	{
		ABAddressBook* addressBook = [ABAddressBook sharedAddressBook];
		ABSearchElement* emailSearchElement = [ABPerson searchElementForProperty:kABEmailProperty
																		   label:nil
																			 key:nil
																		   value:email
																	  comparison:kABEqualCaseInsensitive];
		
		NSArray* peopleFound = [addressBook recordsMatchingSearchElement:emailSearchElement];
		
		if ([peopleFound count] > 0)
		{
			if ([peopleFound count] > 1)
			{
				NSLog(@"Note: %d people found for email %@; will use a picture for the first person.", (int)[peopleFound count], email);
			}
			ABPerson* firstPerson = [peopleFound objectAtIndex:0];
			
			NSData* imageData = [firstPerson imageData];
			
			if (imageData)
			{
				NSImage* newImage = [[[NSImage alloc] initWithData:imageData] autorelease];
				if (newImage)
				{
					[self.cache setObject:newImage forKey:email cost:[imageData length]];
					if (aBlock) aBlock();
					return;
				}
				else
				{
					NSLog(@"Error: cannot instantiate NSImage from AddressBook image data (%d bytes)", (int)imageData.length);
				}
			}
		}
	}
	
	// 2. TODO: Get image from the remote AddressBook entry
	
	{
		
	}
	
	// 3. Gravatar image
	
	{
		NSString* md5hexdigest = [email md5hexdigest];
		NSURL* imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?d=404", md5hexdigest]];
		
		OAHTTPDownload* aDownload = [OAHTTPDownload downloadWithURL:imageURL];
		aDownload.block = ^{
			if (!aDownload.error && aDownload.data)
			{
				NSData* imageData = aDownload.data;
				NSImage* newImage = [[[NSImage alloc] initWithData:imageData] autorelease];
				[self.cache setObject:newImage forKey:email cost:[imageData length]];
				if (aBlock) aBlock();
			}
		};
		[self.httpQueue addDownload:aDownload];
	}
}

- (void) cancel
{
	[self.httpQueue cancel];
}

- (void) removeCachedImages
{
	[self.cache removeAllObjects];
}

@end
