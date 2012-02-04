//
//  GBOptimizeRepositoryController.m
//  gitbox
//
//  Created by Oleg Andreev on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GBOptimizeRepositoryController.h"

@implementation GBOptimizeRepositoryController
@synthesize progressIndicator;
@synthesize pathLabel;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
	{
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.pathLabel.stringValue = @"";
}

@end
