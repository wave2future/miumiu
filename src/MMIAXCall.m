//
//  MMIAXCall.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMIAXCall.h"
#import "MMIAX.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMCallDelegate.h"

@implementation MMIAXCall

-(id) initWithSession:(struct iax_session *)_session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax
{
	if ( self = [super initWithCallDelegate:_delegate] )
	{
		iax = [_iax retain];
		
		session = _session;
		[iax registerIAXCall:self withSession:session];
		
		sessionValid = YES;
	}
	return self;
}

-(id) initWithFormat:(unsigned)_format session:(struct iax_session *)_session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax
{
	if ( self = [self initWithSession:_session callDelegate:_delegate iax:_iax] )
	{
		format = _format;
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

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
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
	[self.delegate callDidEnd:self];
}

-(void) handleEvent:(struct iax_event *)event
{
	switch ( event->etype )
	{
		case IAX_EVENT_ACCEPT:
			format = event->ies.format;
			break;
		case IAX_EVENT_RINGA:
			[delegate callDidBeginRinging:self];
			break;
		case IAX_EVENT_ANSWER:
		{
			MMCodec *encoder, *decoder;
			if ( format == AST_FORMAT_SPEEX )
			{
				encoder = [MMSpeexEncoder codec];
				decoder = [MMSpeexDecoder codec];
			}
			else
			{
				encoder = [MMULawEncoder codec];
				decoder = [MMULawDecoder codec];
			}
			[delegate call:self didAnswerWithEncoder:encoder decoder:decoder];
		}
		break;
		case IAX_EVENT_VOICE:
			[self pushData:event->data ofSize:event->datalen numSamples:MM_DATA_NUM_SAMPLES_UNKNOWN];
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
