//
//  MMSpeexEncoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSpeexEncoder.h"

@implementation MMSpeexEncoder

-(id) init
{
	if ( self = [super init] )
	{
		speex_bits_init( &bits ); 

		enc_state = speex_encoder_init( &speex_nb_mode );
		
		spx_int32_t samplingRate = 8000;
		speex_encoder_ctl( enc_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );

		spx_int32_t quality = 8;
		speex_encoder_ctl( enc_state, SPEEX_SET_QUALITY, &quality );

		speex_encoder_ctl( enc_state, SPEEX_GET_FRAME_SIZE, &samplesPerFrame );
		
		buffer = [[MMCircularBuffer alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[buffer release];
	
	speex_bits_destroy(&bits);
	
	speex_encoder_destroy(enc_state); 

	[super dealloc];
}

-(void) encodeFrame:(short *)frame
{
	speex_bits_reset( &bits );
	
	speex_encode_int( enc_state, frame, &bits ); 

	static const int dataSize = 256;
	char data[dataSize];
	int dataUsed = speex_bits_write( &bits, data, dataSize );
	
	[self produceData:data ofSize:dataUsed numSamples:samplesPerFrame];
}

-(void) consumeData:(void *)_data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	const char *data = (char *)_data;
	unsigned frameSize = samplesPerFrame * sizeof(short);
	
	if ( buffer.used == 0 )
	{
		while ( size >= frameSize )
		{
			[self encodeFrame:(short *)data];
			data += frameSize;
			size -= frameSize;
		}
	}
	
	if ( size == 0 )
		return;
		
	[buffer putData:data ofSize:size];
	
	if ( buffer.used > frameSize )
	{
		spx_int16_t *frame = alloca( frameSize );
		while ( [buffer getData:frame ofSize:frameSize] )
			[self encodeFrame:frame];
	}
}

@end
