#import "GBRepository.h"
#import "GBOptimizeRepositoryController.h"
#import "GBTaskWithProgress.h"

NSString* const GBOptimizeRepositoryNotification = @"GBOptimizeRepositoryNotification";

#if 1
static const NSTimeInterval idleInterval = 4*3600.0;
static const NSTimeInterval checkInterval = 60.0;
static const double actionProbability = 0.05;
#else
#warning Debug: short intervals for optimizing in background.
static const NSTimeInterval idleInterval = 10.0;
static const NSTimeInterval checkInterval = 6.0;
static const double actionProbability = 0.5;
#endif

static NSTimeInterval lastResetTimestamp = 0;
static NSTimeInterval lastCheckTimestamp = 0;
static BOOL running = NO;
static id monitor = nil;

@interface GBOptimizeRepositoryController ()
@property(nonatomic) GBRepository* repository;
@property(nonatomic) GBTaskWithProgress* task;
@property(nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property(nonatomic) IBOutlet NSTextField *pathLabel;
+ (void) scheduleCheck;
+ (void) resetTimeout;
@end

@implementation GBOptimizeRepositoryController {
	BOOL started;
}


+ (GBOptimizeRepositoryController*) controllerWithRepository:(GBRepository*)repo
{
	GBOptimizeRepositoryController* ctrl = [[self alloc] initWithWindowNibName:@"GBOptimizeRepositoryController"];
	ctrl.repository = repo;
	return ctrl;
}

- (void) start
{
	if (started) return;
	started = YES;
	
	self.pathLabel.stringValue = [[self.repository.url absoluteURL] path];
		
	GBTaskWithProgress* gitgcTask = [GBTaskWithProgress taskWithRepository:self.repository];
	if (![GBTask isSnowLeopard])
	{
		gitgcTask.arguments = [NSArray arrayWithObjects:@"gc", @"--progress", nil];
	}
	else
	{
		gitgcTask.arguments = [NSArray arrayWithObjects:@"gc", nil];
	}
		
	[self.progressIndicator setIndeterminate:YES];
	[self.progressIndicator startAnimation:nil];
	
	gitgcTask.sendingRatio = 0.0; // as there's nothing to send.
	
	gitgcTask.progressUpdateBlock = ^{
		double progress = gitgcTask.extendedProgress;
		
		//NSLog(@"Progress: %f [%@]", progress, self.repository.url);
		
		self.progressIndicator.doubleValue = progress;
		
		BOOL newIndeterminate = (progress < 2.0 || progress > 99.0);
		if (newIndeterminate != self.progressIndicator.isIndeterminate)
		{
			[self.progressIndicator stopAnimation:nil];
			if (newIndeterminate)
			{
				self.progressIndicator.doubleValue = 0.0;
				[self.progressIndicator setIndeterminate:YES];
				[self.progressIndicator startAnimation:nil];
			}
			else
			{
				[self.progressIndicator setIndeterminate:NO];
			}
		}
	};
	
	[gitgcTask launchWithBlock:^{
		
		//NSLog(@"Done!");
		[self.progressIndicator stopAnimation:nil];
		[self.progressIndicator setIndeterminate:YES];
		
		self.task = nil;
		
		[self performCompletionHandler:NO];
		//NSLog(@"Finished optimization %@", self.repository.path);
	}];
	
	//NSLog(@"Began optimization %@", self.repository.path);
	self.task = gitgcTask;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	[self start];
}




#pragma mark - Monitoring


+ (BOOL) randomShouldOptimize
{
	return ((double)arc4random() < actionProbability*((double)UINT32_MAX));
}

+ (void) startMonitoring
{
	running = YES;
	
	lastCheckTimestamp = [[NSDate date] timeIntervalSince1970];
	
	[self resetTimeout];
	[self scheduleCheck];
	
	monitor = [NSEvent addLocalMonitorForEventsMatchingMask:
	 NSLeftMouseDownMask   |
	 NSRightMouseDownMask  |
	 NSMouseMovedMask      |
	 NSMouseEnteredMask    |
	 NSMouseExitedMask     |
	 NSKeyDownMask         |
	 NSFlagsChangedMask    |
	 NSScrollWheelMask handler:^(NSEvent *event) {
		 //NSLog(@"Received event %@. Resetting timeout.", event);
		 if (drand48() < 0.1) // do not ping every mouse move
		 {
			 [self resetTimeout];
		 }
		 return event;
	 }];
}

+ (void) stopMonitoring
{
	running = NO;
	[NSEvent removeMonitor:monitor];
	monitor = nil;
}

+ (void) scheduleCheck
{
	if (!running) return;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, checkInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if (!running) return;
		
		// If next check occured after longer interval, it's probably because computer was in sleep and now woke up.
		// Should reset timeout because person does not want to watch some repos optimizing at this point.
		if ([[NSDate date] timeIntervalSince1970] > (lastCheckTimestamp + checkInterval*2))
		{
			//NSLog(@"Sleep wake up detected!");
			[self resetTimeout];
		}
		
		lastCheckTimestamp = [[NSDate date] timeIntervalSince1970];
		
		if ([[NSDate date] timeIntervalSince1970] > (lastResetTimestamp + idleInterval))
		{
			//NSLog(@"Notification: Optimize repositories!");
			[[NSNotificationCenter defaultCenter] postNotificationName:GBOptimizeRepositoryNotification object:nil];
			[self resetTimeout];
		}
		[self scheduleCheck];
	});
}

+ (void) resetTimeout
{
	lastResetTimestamp = [[NSDate date] timeIntervalSince1970];
}


@end
