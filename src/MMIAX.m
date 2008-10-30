//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMIAX.h"
#import "MMIAXCall.h"
#import "MMProtocolDelegate.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMCallDelegate.h"

static void socketCallback(
	CFSocketRef s,
	CFSocketCallBackType callbackType,
	CFDataRef address,
	const void *data,
	void *info
	)
{
	MMIAX *iax = (MMIAX *)info;
	[iax socketCallbackCalled];
}

static void iaxOutputCallback( const char *data )
{
	NSLog( @"IAX Output: %s", data );
}

static void iaxErrorCallback( const char *data )
{
	NSLog( @"IAX Error: %s", data );
}

@implementation MMIAX

-(id) initWithProtocolDelegate:(id <MMProtocolDelegate>)_delegate;
{
	if ( self = [super initWithProtocolDelegate:_delegate] )
	{
#ifdef DEBUG 
		iax_enable_debug();
		iax_set_output( iaxOutputCallback );
		iax_set_error( iaxErrorCallback );
#endif
		
		iax_init( 0 );

		socketContext.info = self;
		CFSocketRef socket = CFSocketCreateWithNative( NULL, iax_get_fd(), kCFSocketReadCallBack,
			socketCallback, &socketContext );
		CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource( NULL, socket, 0 );
		CFRunLoopAddSource( CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes );

		session = iax_session_new();
		
		iax_register( session, [hostname UTF8String], [username UTF8String], [password UTF8String], 1 );
	}
	return self;
}

-(void) dealloc
{
	iax_destroy( session );
	[super dealloc];
}

-(void) registerIAXCall:(MMIAXCall *)iaxCall withSession:(struct iax_session *)callSession
{
	calls[numCalls].session = callSession;
	calls[numCalls++].iaxCall = iaxCall;
}

-(void) unregisterIAXCall:(MMIAXCall *)iaxCall withSession:(struct iax_session *)callSession
{
	for ( unsigned i=0; i<numCalls; ++i )
	{
		if ( calls[i].session == callSession && calls[i].iaxCall == iaxCall )
		{
			memmove( &calls[i], &calls[i+1], (numCalls - i - 1)*sizeof(calls[0]) );
			--numCalls;
			break;
		}
	}
}

-(MMCall *) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	if ( numCalls >= MM_IAX_MAX_NUM_CALLS )
		return nil;
		
	struct iax_session *newSession = iax_session_new();
	
	char *ich = strdup( [[NSString stringWithFormat:@"%@:%@@%@/%@", username, password, hostname, number] UTF8String] );
	iax_call( newSession, [cidNumber UTF8String], [cidName UTF8String], ich, NULL, 0, AST_FORMAT_ULAW, AST_FORMAT_ULAW | AST_FORMAT_SPEEX );
	free( ich );
		
	MMCall *result = [[[MMIAXCall alloc] initWithSession:newSession callDelegate:callDelegate iax:self] autorelease];
	[callDelegate callDidBegin:result];
	return result;
}

-(MMCall *) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate
{
	if ( numCalls >= MM_IAX_MAX_NUM_CALLS )
		return nil;
	
	MMCodec *encoder, *decoder;
	if ( callingFormat == AST_FORMAT_SPEEX )
	{
		encoder = [MMSpeexEncoder codec];
		decoder = [MMSpeexDecoder codec];
	}
	else
	{
		encoder = [MMULawEncoder codec];
		decoder = [MMULawDecoder codec];
	}
	
	iax_answer( callingSession );
	
	MMCall *result = [[[MMIAXCall alloc] initWithFormat:callingFormat session:callingSession callDelegate:callDelegate iax:self] autorelease];
	callingSession = NULL;
	[callDelegate callDidBegin:result];
	[callDelegate call:result didAnswerWithEncoder:encoder decoder:decoder];
	return result;
}

-(void) ignoreCall
{
	iax_reject( callingSession, "Refused" );
	callingSession = NULL;
}

-(void) socketCallbackCalled
{
	struct iax_event *event;
	while ( event = iax_get_event( 0 ) )
	{
		if ( event->etype != IAX_EVENT_NULL )
		{
			BOOL foundSession = NO;
			
			for ( unsigned i=0; i<numCalls; ++i )
			{
				if ( calls[i].session == event->session )
				{
					NSLog( @"Found IAXCall for session %p", event->session );
					foundSession = YES;
					[calls[i].iaxCall handleEvent:event];
					break;
				}
			}
			
			if ( !foundSession )
			{
				switch ( event->etype )
				{
					case IAX_EVENT_CONNECT:
						callingSession = event->session;
						
						if ( event->ies.format & AST_FORMAT_SPEEX )
							callingFormat = AST_FORMAT_SPEEX;
						else if ( event->ies.format & AST_FORMAT_ULAW )
							callingFormat = AST_FORMAT_ULAW;
						else
							callingFormat = 0;
						
						if ( callingFormat == 0 )
							iax_reject( callingSession, "No codec found" );
						else
						{
							iax_accept( callingSession, callingFormat );
							NSLog( @"Connect: session=%p, event->session=%p", session, event->session);
							iax_ring_announce( callingSession );
							[delegate protocol:self isReceivingCallFrom:[NSString stringWithFormat:@"%s <%s>", event->ies.calling_name, event->ies.calling_number]];
						}
						
						break;
					
					default:
						NSLog( @"Unknown event %u for session %p", (unsigned)event->etype, event->session );
						break;
				}
			}
		}
		
		iax_event_free( event );
	}
}

@end
