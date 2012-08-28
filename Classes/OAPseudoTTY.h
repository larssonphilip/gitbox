#import <Foundation/Foundation.h>

// How to use:
// 1. Create an instance, it opens a pseudo tty when initialized.
// 2. Connect slaveFileHandle as stdout, stdin and stderr to NSTask instance.
// 3. Read and write to masterFileHandle.

@interface OAPseudoTTY : NSObject

@property(nonatomic, copy,   readonly) NSString* name;
@property(nonatomic, strong, readonly) NSFileHandle* masterFileHandle;
@property(nonatomic, strong, readonly) NSFileHandle* slaveFileHandle;

@end
