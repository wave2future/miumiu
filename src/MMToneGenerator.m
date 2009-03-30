//
//  MMToneGenerator.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMToneGenerator.h"

#include <limits.h>

@implementation MMToneGenerator

-(id) initWithNumTones:(unsigned)_numTones
	amplitudes:(const float *)_amplitudes
	frequencies:(const float *)_frequencies
	samplingFrequency:(float)_samplingFrequency
{
	if ( self = [super init] )
	{
		numTones = _numTones;

		unsigned amplitudesSize = numTones * sizeof(float);
		amplitudes = malloc( amplitudesSize );
		memcpy( amplitudes, _amplitudes, amplitudesSize );
		
		unsigned multipliersSize = numTones * sizeof(float);
		multipliers = malloc( multipliersSize );
		for ( unsigned i=0; i<numTones; ++i )
			multipliers[i] = (float)_frequencies[i] * 2 * M_PI / (float)_samplingFrequency;
	}
	return self;
}

-(void) dealloc
{
	free( multipliers );
	free( amplitudes );
	[super dealloc];
}

-(void) injectSamples:(short *)samples count:(unsigned)count offset:(unsigned)offset
{
	for ( unsigned i=0; i<count; ++i )
	{
		float sample = 0;
		for ( unsigned j=0; j<numTones; ++j )
			sample += amplitudes[j] * sinf( (offset + i) * multipliers[j] );
		samples[i] += roundf( sample );
	}
}

@end
