//
//  MMComfortNoiseInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMComfortNoiseInjector.h"

@implementation MMComfortNoiseInjector

#pragma mark MMSampleConsumer

-(void) reset
{
	lfsr = 0xACE1u;
	lastInjection = 0;
	[super reset];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	for ( unsigned i=0; i<count; ++i )
	{
		lfsr = (lfsr >> 1) ^ (-(short)(lfsr & 1u) & 0xB400u);
		short injection = (short)lfsr >> 10;
		injection -= (injection - lastInjection) >> 1;
		samples[i] += injection;
		lastInjection = injection;
	}
	[super consumeSamples:samples count:count];
}

@end
