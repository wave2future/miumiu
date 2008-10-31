//
//  MMComfortNoiseInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMComfortNoiseInjector.h"

@implementation MMComfortNoiseInjector

-(id) init
{
	if ( self = [super init] )
	{
		lfsr = 0xACE1u;
		lastInjection = 0;
	}
	return self;
}

-(void) processData:(void *)data ofSize:(unsigned)size
{
	unsigned numSamples = size/sizeof(short);
	short *samples = data;
	for ( unsigned i=0; i<numSamples; ++i )
	{
		lfsr = (lfsr >> 1) ^ (-(short)(lfsr & 1u) & 0xB400u);
		short injection = (short)lfsr >> 10;
		injection -= (injection - lastInjection) >> 1;
		samples[i] += injection;
		lastInjection = injection;
	}
}

@end
