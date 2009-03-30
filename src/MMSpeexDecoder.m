//
//  MMSpeexDecoder.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSpeexDecoder.h"
#import "MMDecoderTarget.h"

@implementation MMSpeexDecoder

#pragma mark Private

-(void) start
{
	speex_bits_init( &bits );
	
	dec_state = speex_decoder_init( &speex_nb_mode ); 
	
	spx_int32_t samplingRate = 8000;
	speex_decoder_ctl( dec_state, SPEEX_SET_SAMPLING_RATE, &samplingRate );
	
	speex_decoder_ctl( dec_state, SPEEX_GET_FRAME_SIZE, &samplesPerFrame );
}

-(void) stop
{
	speex_bits_destroy( &bits );
	
	speex_decoder_destroy( dec_state );
}

#pragma mark Initialization

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

#pragma mark MMDecoder

-(void) reset
{
	[self stop];
	[self start];
}

-(void) decodeData:(void *)data
	ofSize:(unsigned)size
	toTarget:(id <MMDecoderTarget>)target
{
	speex_bits_read_from( &bits, data, size );
	
	unsigned frameSize = samplesPerFrame * sizeof(short);
	short *frame = alloca( frameSize );
	while ( speex_decode_int( dec_state, &bits, frame ) == 0 )
		[target decoder:self didDecodeSamples:frame count:samplesPerFrame fromData:data ofSize:size];
}

@end
