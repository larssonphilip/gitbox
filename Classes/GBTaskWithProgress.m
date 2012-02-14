#import "GBTaskWithProgress.h"
#import "NSData+OADataHelpers.h"

@interface GBTaskWithProgress ()
@property(nonatomic, retain) NSDate* indeterminateActivityStartDate;

// Returns zero value if could not parse a progress.
+ (double) progressForDataChunk:(NSData*)dataChunk statusRef:(NSString**)statusRef sendingRatio:(double)sendingRatio;

@end

@implementation GBTaskWithProgress

@synthesize progressUpdateBlock;
@synthesize status;
@synthesize progress;
@synthesize extendedProgress;
@synthesize indeterminateActivityStartDate;
@synthesize sendingRatio;

- (void) dealloc
{
	self.progressUpdateBlock = nil;
	self.status = nil;
	self.indeterminateActivityStartDate = nil;
	[super dealloc];
}

- (id)init
{
	if (self = [super init])
	{
		sendingRatio = 0.8;
	}
	return self;
}

- (BOOL) isRealTime
{
	return YES;
}

- (void) callProgressBlock
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.progressUpdateBlock) self.progressUpdateBlock(); 
	});
}

+ (double) progressWithPrefix:(NSString*)prefix line:(NSString*)line
{
	NSRange range = NSMakeRange(0,0);
	if ((range = [line rangeOfString:prefix]).length > 0)
	{
		@try
		{
			NSUInteger offset = range.location+range.length;
			NSUInteger length = 6;
			if ([line length] >= offset + length)
			{
				NSRange progressRange = [line rangeOfString:@"%" options:0 range:NSMakeRange(offset, length)];
				if (progressRange.length > 0)
				{
					progressRange = NSMakeRange(range.location+range.length, progressRange.location - (range.location + range.length));
					NSString* portion = [line substringWithRange:progressRange];
					double partialProgress = [portion doubleValue];
					return partialProgress;
				}
			}
		}
		@catch (NSException *exception)
		{
			NSLog(@"GBTaskWithProgress: exception while parsing progress output: %@ [prefix: %@; line: %@]", exception, prefix, line);
		}
	}
	return 0.0;
}

+ (double) progressForDataChunk:(NSData*)dataChunk statusRef:(NSString**)statusRef sendingRatio:(double)sendingRatio
{
	double newProgress = 0.0;
	
	sendingRatio = MAX(MIN(sendingRatio, 1.0), 0.0);
	
	double compressingRatio = (1.0 - sendingRatio)*0.5;
	double resolvingDeltasRatio = 1.0 - compressingRatio - sendingRatio;
	
	NSString* string = [[dataChunk UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray* lines = [string componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
	if (!lines || [lines count] == 0) return newProgress;
	NSString* line = [lines lastObject];
	if (!line) return newProgress;
	
	//NSLog(@"LINE: %@", line);
	
	/*
	 Fetch:
     warning: templates not found /usr/local/Cellar/git/1.7.3.2/share/git-core/templates
     Cloning into emrpc1...
     remote: Counting objects: 890, done.[K
     remote: Compressing objects:   0% (1/299)   [K
     Receiving objects:   2% (18/890)
     Resolving deltas:  12% (72/578)
	 
	 Push:
     Counting objects: 175, done.
     Delta compression using up to 2 threads.
     Compressing objects: 100% (100/100), done.
     Writing objects: 100% (100/100), 314.12 KiB | 505 KiB/s, done.
     Total 100 (delta 1), reused 0 (delta 0)
     To oleganza@localhost:Work/gitbox/example_repos/progress/src.git
     5151324..0b58b81  master -> master
	 */
	
	double partialProgress = 0.0;
	if ([line rangeOfString:@"Counting objects:"].length > 0)
	{
		if (statusRef) *statusRef = NSLocalizedString(@"Preparing...", @"GBTaskWithProgress");
	}
	else if ((partialProgress = [self progressWithPrefix:@"Compressing objects:" line:line]) > 0.0)
	{
		if (statusRef) *statusRef = NSLocalizedString(@"Packing...", @"GBTaskWithProgress");
		newProgress = compressingRatio*partialProgress;
	}
	else if ((partialProgress = [self progressWithPrefix:@"Receiving objects:" line:line]) > 0.0)
	{
		if (statusRef) *statusRef = NSLocalizedString(@"Downloading...", @"GBTaskWithProgress");
		newProgress = compressingRatio*100.0 + sendingRatio*partialProgress;
	}
	else if ((partialProgress = [self progressWithPrefix:@"Writing objects:" line:line]) > 0.0)
	{
		// When pushing, there's no resolving deltas step.
		if (statusRef) *statusRef = NSLocalizedString(@"Uploading...", @"GBTaskWithProgress");
		newProgress = compressingRatio*100.0 + (sendingRatio + resolvingDeltasRatio)*partialProgress;
	}
	else if ((partialProgress = [self progressWithPrefix:@"Resolving deltas:" line:line]) > 0.0)
	{
		if (statusRef) *statusRef = NSLocalizedString(@"Unpacking...", @"GBTaskWithProgress");
		newProgress = (compressingRatio + sendingRatio)*100.0 + resolvingDeltasRatio*partialProgress;
	}
	
	return newProgress;
}

- (void) didReceiveStandardErrorData:(NSData*)dataChunk
{
	NSString* newStatus = self.status;
	
	double newProgress = [[self class] progressForDataChunk:dataChunk statusRef:&newStatus sendingRatio:sendingRatio];
	if (newProgress <= 0) newProgress = self.progress;
	self.status = newStatus;
    
	double newExtendedProgress = 0.0;
	{
		const double firstPart = 5.0;
		const double lastPart = 10.0;
		const double middlePart = 100.0 - firstPart - lastPart;
		const double fadeRatio = 0.1;
		
		// If we are waiting 
		if (newProgress < 0.1)
		{
			if (!self.indeterminateActivityStartDate)
			{
				self.indeterminateActivityStartDate = [NSDate date];
			}
			
			newExtendedProgress = firstPart*(1.0-exp([self.indeterminateActivityStartDate timeIntervalSinceNow]*fadeRatio));
			//NSLog(@"Phase 1: %f", newExtendedProgress);
		}
		else if (newProgress < 99.9)
		{
			newExtendedProgress = firstPart + middlePart*newProgress*0.01;
			self.indeterminateActivityStartDate = nil; // reset the timer
			//NSLog(@"Phase 2: %f", newExtendedProgress);
		}
		else
		{
			if (!self.indeterminateActivityStartDate)
			{
				self.indeterminateActivityStartDate = [NSDate date];
			}
			newExtendedProgress = firstPart + middlePart + lastPart*(1.0-exp([self.indeterminateActivityStartDate timeIntervalSinceNow]*fadeRatio));
			//NSLog(@"Phase 3: %f", newExtendedProgress);
		}
	}	

	// To avoid heavy load on main thread, call the block only when progress changes by 0.1%.
	if (round(newExtendedProgress*10) == round(self.extendedProgress*10)) return;
	
	self.extendedProgress = newExtendedProgress;
	self.progress = newProgress;
	[self callProgressBlock];
}

- (void) didFinishInBackground
{
	self.progress = 100.0;
	self.status = @"";
	
	[self callProgressBlock];
	self.progressUpdateBlock = nil; // break retain cycle through the block
	[super didFinishInBackground];
}

@end
