//
//  MMToneGenerator.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMToneGenerator.h"

#include <limits.h>

static unsigned gcd( unsigned a, unsigned b )
{
	if ( a == 0 )
		return b;
	else
		return gcd( b % a, a ); 
}

static unsigned lcm( unsigned a, unsigned b )
{
	return a * b / gcd( a, b );
}

@implementation MMToneGenerator

+ (NSData *)generateSampleForAmplitudes:(const short *)amplitudes
	frequencies:(const unsigned *)frequencies
	count:(unsigned)count
	numSamples:(unsigned)numSamples
	samplingFrequency:(unsigned)samplingFrequency
{
	float *multipliers = alloca( count * sizeof(float) );
	for ( unsigned i=0; i<count; ++i )
		multipliers[i] = (float)frequencies[i] * 2 * M_PI / (float)samplingFrequency;
	
	NSMutableData *samples = [NSMutableData dataWithCapacity:numSamples*sizeof(short)];
	for ( unsigned i=0; i<numSamples; ++i )
	{
		short sample = 0;
		for ( unsigned j=0; j<count; ++j )
			sample += roundf( amplitudes[j] * sin( i * multipliers[j] ) );
		[samples appendBytes:&sample length:sizeof(sample)];
	}
	return samples;
}

@end
