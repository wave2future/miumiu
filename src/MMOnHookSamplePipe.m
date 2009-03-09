//
//  MMOnHookSamplePipe.m
//  MiuMiu
//
//  Created by Peter Zion on 08/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MMOnHookSamplePipe.h"

@implementation MMOnHookSamplePipe

#pragma mark MMSampleConsumer

-(void) reset
{
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	memset( samples, 0, count*sizeof(short) );
	[super consumeSamples:samples count:count];
}

@end
