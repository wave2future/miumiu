//
//  MMComfortNoiseInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMComfortNoiseInjector.h"

@implementation MMComfortNoiseInjector

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[super connectToConsumer:consumer];
	lfsr = 0xACE1u;
	lastInjection = 0;
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	short *samples = data;
	for ( unsigned i=0; i<numSamples; ++i )
	{
		lfsr = (lfsr >> 1) ^ (-(short)(lfsr & 1u) & 0xB400u);
		short injection = (short)lfsr >> 9;
		injection -= (injection - lastInjection) >> 1;
		samples[i] += injection;
		lastInjection = injection;
	}
	[self produceData:data ofSize:size numSamples:numSamples];
}

@end
