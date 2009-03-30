//
//  MMULawDecoder.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMULawDecoder.h"
#import "MMDecoderTarget.h"

@implementation MMULawDecoder

#pragma mark Initialization

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

#pragma mark MMDecoder

-(void) reset
{
}

-(void) decodeData:(void *)_data
	ofSize:(unsigned)size
	toTarget:(id <MMDecoderTarget>)target
{
	const unsigned char *data = (const unsigned char *)_data;
	unsigned count = size;
	short *samples = alloca( count * sizeof(short) );
	for ( unsigned i=0; i<count; ++i )
		samples[i] = uLawToLinear[data[i]];
	[target decoder:self didDecodeSamples:samples count:count fromData:data ofSize:size];
}

@end
