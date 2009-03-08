//
//  MMSpeexEncoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSpeexEncoder.h"
#import "MMCircularBuffer.h"
#import "MMEncoderTarget.h"

@implementation MMSpeexEncoder

#pragma mark Private

-(void) start
{
	speex_bits_init( &bits ); 

	enc_state = speex_encoder_init( &speex_nb_mode );
	
	spx_int32_t samplingRate = 8000;
	speex_encoder_ctl( enc_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );

	spx_int32_t vbr = 1;
	speex_encoder_ctl( enc_state, SPEEX_SET_VBR, &vbr );

	float vbrQuality = 4.0;
	speex_encoder_ctl( enc_state, SPEEX_SET_VBR_QUALITY, &vbrQuality );

	spx_int32_t vad = 1;
	speex_encoder_ctl( enc_state, SPEEX_SET_VAD, &vad );

	speex_encoder_ctl( enc_state, SPEEX_GET_FRAME_SIZE, &samplesPerFrame );
	
	buffer = [[MMCircularBuffer alloc] initWithCapacity:(2*160*sizeof(short))];
}

-(void) stop
{
	[buffer release];
	
	speex_bits_destroy(&bits);
	
	speex_encoder_destroy(enc_state); 
}

#pragma mark Initializtion

-(id) init
{
	if ( self = [super init] )
		[self start];
	return self;
}

-(void) dealloc
{
	[self stop];
	[super dealloc];
}

#pragma mark MMEncoder

-(void) reset
{
	[self stop];
	[self start];
}

-(void) encodeSamples:(short *)samples
	count:(unsigned)count
	toTarget:(id <MMEncoderTarget>)target
{
	if ( buffer.used == 0 )
	{
		while ( count >= samplesPerFrame )
		{
			speex_bits_reset( &bits );
			
			speex_encode_int( enc_state, samples, &bits ); 

			static const unsigned maxSize = 256;
			char data[maxSize];
			unsigned size = (unsigned)speex_bits_write( &bits, data, maxSize );
			
			[target encoder:self didEncodeData:data ofSize:size correspondingToSamples:samples count:samplesPerFrame];

			samples += samplesPerFrame;
			count -= samplesPerFrame;
		}
	}
	
	if ( count == 0 )
		return;
		
	[buffer putData:samples ofSize:count*sizeof(short)];
	
	if ( buffer.used > samplesPerFrame*sizeof(short) )
	{
		spx_int16_t *frameSamples = alloca( samplesPerFrame*sizeof(short) );
		while ( [buffer getData:frameSamples ofSize:samplesPerFrame*sizeof(short)] )
		{
			speex_bits_reset( &bits );
			
			speex_encode_int( enc_state, frameSamples, &bits ); 

			static const unsigned maxSize = 256;
			char data[maxSize];
			unsigned size = (unsigned)speex_bits_write( &bits, data, maxSize );
			
			[target encoder:self didEncodeData:data ofSize:size correspondingToSamples:frameSamples count:samplesPerFrame];
		}
	}
}

@end
