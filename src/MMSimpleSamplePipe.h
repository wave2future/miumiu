//
//  MMSimpleSamplePipe.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSamplePipe.h"

@interface MMSimpleSamplePipe : NSObject <MMSamplePipe>
{
@protected
	id <MMSampleConsumer> connectedConsumer;
};

+(id) simpleDataPipe;

@end
