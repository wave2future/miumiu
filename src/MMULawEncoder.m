//
//  MMULawEncoder.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMULawEncoder.h"

@implementation MMULawEncoder

-(id) init
{
	if ( self = [super init] )
	{
		// [pzion 20081010] From iaxclient sources:
		/* this looks similar to asterisk, but comes from public domain code by craig reese
		   I've just followed asterisk's table sizes for lin_2u, and also too lazy to do binary arith to decide which  
		   iterations to skip -- this way we get the same result.. */
		for(int i=-32767;i<32768;i+=4) {
			int sample = i;
			int exp_lut[256] = {0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,
								 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
								 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
								 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
								 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
								 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
								 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
								 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
								 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7};
			int sign, exponent, mantissa;
			unsigned char ulawbyte;

			/* Get the sample into sign-magnitude. */
			sign = (sample >> 8) & 0x80;            /* set aside the sign */
			if (sign != 0) sample = -sample;                /* get magnitude */
			if (sample > 32635) sample = 32635;             /* clip the magnitude */

			/* Convert from 16 bit linear to ulaw. */
			sample = sample + 0x84;
			exponent = exp_lut[(sample >> 7) & 0xFF];
			mantissa = (sample >> (exponent + 3)) & 0x0F;
			ulawbyte = ~(sign | (exponent << 4) | mantissa);
			if (ulawbyte == 0) ulawbyte = 0x02;     /* optional CCITT trap */
	  
			linearToULaw[((unsigned short)i) >> 2] = ulawbyte;
		}
	}
	return self;
}

-(void) consumeData:(void *)_data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	short *samples = (short *)_data;
	unsigned newSize = numSamples * sizeof(unsigned char);
	unsigned char *newSamples = alloca( newSize );
	for ( unsigned i=0; i<numSamples; ++i )
		newSamples[i] = linearToULaw[((unsigned short)samples[i])>>2];
	[self produceData:newSamples ofSize:numSamples numSamples:numSamples];
}

@end
