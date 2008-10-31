//
//  MMPreprocessor.m
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPreprocessor.h"

@implementation MMPreprocessor

-(id) init
{
	if ( self = [super init] )
	{
		self.dataPipeDelegate = self;
	}
	return self;
}

-(void) dataPipe:(MMDataPipe *)dataPipe didConnectToTarget:(MMDataPipe *)newTarget
{
	state = speex_preprocess_state_init( 160, 8000 );
	spx_int32_t disable = 0, enable = 1;
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_DENOISE, &disable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_AGC, &enable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_VAD, &enable );
	speex_preprocess_ctl( state, SPEEX_PREPROCESS_SET_DEREVERB, &disable );
}

-(void) dataPipe:(MMDataPipe *)dataPipe willDisconnectFromTarget:(MMDataPipe *)oldTarget
{
	speex_preprocess_state_destroy( state );
	state = NULL;
}

-(void) processData:(void *)data ofSize:(unsigned)size
{
	if ( !speex_preprocess_run( state, data ) )
		memset( data, 0, size );
}

@end
