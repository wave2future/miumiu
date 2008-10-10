//
//  MMSpeexEncoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSpeexEncoder.h"

@implementation MMSpeexEncoder

-(void) start
{
	if ( !running )
	{
		speex_bits_init( &bits ); 

		enc_state = speex_encoder_init( &speex_nb_mode );
		
		spx_int32_t samplingRate = 8000;
		speex_encoder_ctl( enc_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );

		spx_int32_t quality = 8;
		speex_encoder_ctl( enc_state, SPEEX_SET_QUALITY, &quality );

		speex_encoder_ctl( enc_state, SPEEX_GET_FRAME_SIZE, &frameSize );
		frameSize *= sizeof(spx_int16_t);
		frame = malloc( frameSize );
		
		running = YES;
	}
}

-(void) fromBuffer:(MMCircularBuffer *)src toBuffer:(MMCircularBuffer *)dst
{
	while ( [src getData:frame ofSize:frameSize] )
	{
		speex_bits_reset( &bits );
		
		speex_encode_int( enc_state, (spx_int16_t *)frame, &bits ); 

		static const int bufferSize = 256;
		char buffer[bufferSize];
		int bufferCount = speex_bits_write( &bits, buffer, bufferSize );
		
		[dst putData:buffer ofSize:bufferCount];

		//NSLog( @"MMSpeexEncoder: encoded %u bytes to %d bytes", frameSize, bufferCount );
	}
}

-(void) stop
{
	if ( running )
	{
		free( frame );
		
		speex_bits_destroy(&bits);
		
		speex_encoder_destroy(enc_state); 

		running = NO;
	}
}

@end
