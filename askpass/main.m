#import <Foundation/Foundation.h>
#import "GBAskPass.h"

// The askpass utility is called with prompt as its first argument.
// Whatever it returns on STDOUT is consumed as a result.

int main (int argc, const char * argv[])
{
  return GBAskPass(argc, argv);
}

