//
//  MMPreprocessor.m
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPreprocessor.h"

@implementation MMPreprocessor

#pragma mark Private

-(void) start
{
	state = speex_preprocess_state_init( 160, 8000 );
	spx_int32_t disable = 0, enable = 1;
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_DENOISE, &disable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_AGC, &enable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_VAD, &enable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_DEREVERB, &disable );
}

-(void) stop
{
	speex_preprocess_state_destroy( state );
	state = NULL;
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

#pragma mark MMSampleConsumer

-(void) reset
{
	[self stop];
	[self start];
	[super reset];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	if ( !speex_preprocess_run( state, samples ) )
		memset( samples, 0, count*sizeof(short) );
	[super consumeSamples:samples count:count];
}

@end
