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

-(void) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	if ( numCalls >= MM_IAX_MAX_NUM_CALLS )
		return;
		
	struct iax_session *newSession = iax_session_new();
	
	char *ich = strdup( [[NSString stringWithFormat:@"%@:%@@%@/%@", username, password, hostname, number] UTF8String] );
	iax_call( newSession, [cidNumber UTF8String], [cidName UTF8String], ich, NULL, 0, AST_FORMAT_SPEEX, AST_FORMAT_ULAW | AST_FORMAT_SPEEX );
	free( ich );
		
	[[[MMIAXCall alloc] initWithSession:newSession callDelegate:callDelegate iax:self] autorelease];
}

-(void) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate
{
	if ( numCalls >= MM_IAX_MAX_NUM_CALLS )
		return;
	
	iax_answer( callingSession );
	[[[MMIAXCall alloc] initWithFormat:callingFormat session:callingSession callDelegate:callDelegate iax:self] autorelease];
	callingSession = NULL;
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
							iax_ring_announce( callingSession );
							[delegate protocol:self isReceivingCallFrom:[NSString stringWithFormat:@"%s <%s>", event->ies.calling_name, event->ies.calling_number]];
						}
						
						break;
				}
			}
		}
		
		iax_event_free( event );
	}
}

@end
