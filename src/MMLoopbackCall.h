//
//  MMLoopbackCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMCall.h"
#import "MMSimpleSamplePipe.h"

@protocol MMCallDelegate;

@interface MMLoopbackCall : MMSimpleSamplePipe <MMCall>
{
@private
	id <MMCallDelegate> delegate;
}

#pragma mark Initialization

-(id) initWithCallDelegate:(id <MMCallDelegate>)_delegate;

@end
