
#import "OAPseudoTTY.h"

#import <util.h>
#include <sys/ioctl.h>
#include <unistd.h>

@interface OAPseudoTTY ()
@property(nonatomic, copy, readwrite) NSString* name;
@property(nonatomic, retain, readwrite) NSFileHandle* masterFileHandle;
@property(nonatomic, retain, readwrite) NSFileHandle* slaveFileHandle;
@end

@implementation OAPseudoTTY

@synthesize name;
@synthesize masterFileHandle;
@synthesize slaveFileHandle;

- (id) init
{
  if ((self = [super init]))
  {
    int masterfd, slavefd;
    char devname[64];
    if (openpty(&masterfd, &slavefd, devname, NULL, NULL) == -1)
    {
      [NSException raise:@"OpenPtyErrorException"
                  format:@"%s", strerror(errno)];
    }
    self.name = [[[NSString alloc] initWithCString:devname] autorelease];
    self.slaveFileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:slavefd] autorelease];
    self.masterFileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:masterfd
                                              closeOnDealloc:YES] autorelease];
    
    if (setsid() < 0)
    {
	    perror("setsid");
    }
    
    if (ioctl(slavefd, TIOCSCTTY, NULL) < 0)
    {
	    perror("setting control terminal");
    }
  }
  return self;
}

-(void)dealloc
{
  [name release]; name = nil;
  [slaveFileHandle release]; slaveFileHandle = nil;
  [masterFileHandle release]; masterFileHandle = nil;
  [super dealloc];
}

@end
