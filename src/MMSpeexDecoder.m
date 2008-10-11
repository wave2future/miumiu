//
//  MMSpeexDecoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSpeexDecoder.h"

@implementation MMSpeexDecoder

-(id) init
{
	if ( self = [super init] )
	{
		speex_bits_init( &bits );
		
		dec_state = speex_decoder_init( &speex_nb_mode ); 
		
		spx_int32_t samplingRate = 8000;
		speex_decoder_ctl( dec_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );
		
		speex_decoder_ctl( dec_state, SPEEX_GET_FRAME_SIZE, &samplesPerFrame );
	}
	return self;
}

-(void) dealloc
{
	speex_bits_destroy( &bits );
	
	speex_decoder_destroy( dec_state );
	
	[super dealloc];
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	speex_bits_read_from( &bits, data, size );
	
	unsigned frameSize = samplesPerFrame * sizeof(short);
	short *frame = alloca( frameSize );
	while ( speex_decode_int( dec_state, &bits, frame ) == 0 )
		[self produceData:frame ofSize:frameSize numSamples:samplesPerFrame];
}

@end
