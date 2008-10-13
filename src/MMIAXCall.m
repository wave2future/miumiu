//
//  MMIAXCall.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMIAXCall.h"
#import "MMIAX.h"

@implementation MMIAXCall

-(id) initWithNumber:(NSString *)number iax:(MMIAX *)_iax
{
	if ( self = [super init] )
	{
		iax = [_iax retain];
		
		session = iax_session_new();
		[iax registerIAXCall:self withSession:session];
		
		char *ich = strdup( [[NSString stringWithFormat:@"%@:%@@%@/%@", iax.username, iax.password, iax.hostname, number] UTF8String] );
		iax_call( session, [iax.cidNumber UTF8String], [iax.cidName UTF8String], ich, NULL, 0, AST_FORMAT_ULAW, AST_FORMAT_ULAW | AST_FORMAT_SPEEX );
		free( ich );
		
		sessionValid = YES;
	}
	return self;
}

-(void) dealloc
{
	[iax unregisterIAXCall:self withSession:session];
	if ( sessionValid )
		iax_destroy( session );
	
	[iax release];
	
	[super dealloc];
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( sessionValid )
		iax_send_voice( session, format, data, size, numSamples );
}

-(void) sendDTMF:(NSString *)dtmf
{
	if ( sessionValid )
		iax_send_dtmf( session, *[dtmf UTF8String] );
}

-(void) end
{
	if ( sessionValid )
	{
		iax_hangup( session, "later!" );
		sessionValid = NO;
	}
	[delegate callDidEnd:self];
}

-(void) handleEvent:(struct iax_event *)event
{
	if ( !sentBegin )
	{
		[delegate callDidBegin:self];
		sentBegin = YES;
	}
	
	switch ( event->etype )
	{
		case IAX_EVENT_ACCEPT:
			format = event->ies.format;
			break;
		case IAX_EVENT_RINGA:
			[delegate callDidBeginRinging:self];
			break;
		case IAX_EVENT_ANSWER:
			[delegate call:self didAnswerWithUseSpeex:(format==AST_FORMAT_SPEEX)];
			break;
		case IAX_EVENT_VOICE:
			[self produceData:event->data ofSize:event->datalen numSamples:MM_DATA_NUM_SAMPLES_UNKNOWN];
			break;
		case IAX_EVENT_REJECT:
			sessionValid = NO;
			[delegate callDidFail:self];
			break;
		case IAX_EVENT_BUSY:
			[delegate callDidReturnBusy:self];
			break;
		case IAX_EVENT_HANGUP:
			[delegate callDidEnd:self];
			break;
	}
}

@end
