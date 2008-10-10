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
		frame = malloc( frameSize );
		
		running = YES;
	}
}

-(void) fromBuffer:(MMCircularBuffer *)src toBuffer:(MMCircularBuffer *)dst;
{
	int bufferSize = src.used;
	if ( bufferSize == 0 )
		return;
	char *buffer = alloca( bufferSize );

	//NSLog( @"MMSpeexDecoder: decoding %d bytes", bufferSize );

	[src getData:buffer ofSize:bufferSize];

	speex_bits_read_from( &bits, buffer, bufferSize );
		
	while ( speex_decode_int( dec_state, &bits, frame ) == 0 )
	{
		//NSLog( @"MMSpeexDecoder: decoded to %u bytes", frameSize );
		[dst putData:frame ofSize:frameSize];
		break;
	}
}

-(void) stop
{
	if ( running )
	{
		free( frame );
		
		speex_bits_destroy( &bits );
		
		speex_decoder_destroy( dec_state );
	
		running = NO;
	}
}

@end
