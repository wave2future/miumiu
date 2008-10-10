//
//  MMSpeexDecoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSpeexDecoder.h"

@implementation MMSpeexDecoder

-(void) start
{
	if ( !running )
	{
		speex_bits_init( &bits );
		
		dec_state = speex_decoder_init( &speex_nb_mode ); 
		
		spx_int32_t samplingRate = 8000;
		speex_decoder_ctl( dec_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );
		
		speex_decoder_ctl( dec_state, SPEEX_GET_FRAME_SIZE, &frameSize );
		frameSize *= sizeof(spx_int16_t);
		
		running = YES;
	}
}

-(void) consumeData:(void *)data ofSize:(unsigned)size
{
	speex_bits_read_from( &bits, data, size );
	
	spx_int16_t *frame = alloca( frameSize );
	while ( speex_decode_int( dec_state, &bits, frame ) == 0 )
		[self produceData:frame ofSize:frameSize];
}

-(void) stop
{
	if ( running )
	{
		speex_bits_destroy( &bits );
		
		speex_decoder_destroy( dec_state );
	
		running = NO;
	}
}

@end
