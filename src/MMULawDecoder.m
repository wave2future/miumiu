//
//  MMULawDecoder.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMULawDecoder.h"

@implementation MMULawDecoder

-(id) init
{
	if ( self = [super init] )
	{
		// [pzion 20081010] From iaxclient sources:
		/* this looks similar to asterisk, but comes from public domain code by craig reese
		   I've just followed asterisk's table sizes for lin_2u, and also too lazy to do binary arith to decide which  
		   iterations to skip -- this way we get the same result.. */
		for(unsigned i=0;i<256;i++) {
			  int b = ~i; 
			  int exp_lut[8] = {0,132,396,924,1980,4092,8316,16764};
			  int sign, exponent, mantissa, sample;
		
			  sign = (b & 0x80);
			  exponent = (b >> 4) & 0x07;
			  mantissa = b & 0x0F;
			  sample = exp_lut[exponent] + (mantissa << (exponent + 3));
			  if (sign != 0) sample = -sample;
			  uLawToLinear[i] = sample;
		}
	}
	return self;
}

-(void) consumeData:(void *)_data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( numSamples == MM_DATA_NUM_SAMPLES_UNKNOWN )
		numSamples = size;
	const unsigned char *samples = _data;
	unsigned newSize = numSamples * sizeof(short);
	short *newSamples = alloca( newSize );
	for ( unsigned i=0; i<numSamples; ++i )
		newSamples[i] = uLawToLinear[samples[i]];
	[self produceData:newSamples ofSize:newSize numSamples:numSamples];
}

@end
