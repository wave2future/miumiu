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

void willDestroySessionCallback( struct iax_session *session, void *userdata )
{
	[(MMIAX *)userdata willDestroySession];
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
		iax_set_will_destroy_session_handler( session, willDestroySessionCallback, self );
		iax_register( session, [hostname UTF8String], [username UTF8String], [password UTF8String], 1 );
		
		reregistrationTimer = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(reregister) userInfo:nil repeats:YES] retain];
	}
	return self;
}

-(void) dealloc
{
	[reregistrationTimer invalidate];
	[reregistrationTimer release];
	iax_unregister( session, [hostname UTF8String], [username UTF8String], [password UTF8String], NULL );
	iax_set_will_destroy_session_handler( session, NULL, NULL );
	iax_session_destroy( &session );
	[super dealloc];
}

-(void) willDestroySession
{
	[call end];
	[call release];
	call = nil;
	
	session = iax_session_new();
	iax_set_will_destroy_session_handler( session, willDestroySessionCallback, self );
	iax_register( session, [hostname UTF8String], [username UTF8String], [password UTF8String], 1 );
}

-(void) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	struct iax_session *oldSession = session;
	session = NULL;
	iax_unregister( oldSession, [hostname UTF8String], [username UTF8String], [password UTF8String], NULL );
	iax_set_will_destroy_session_handler( oldSession, NULL, NULL );
	iax_session_destroy( &oldSession );
	
	session = iax_session_new();
	iax_set_will_destroy_session_handler( session, willDestroySessionCallback, self );
	char *ich = strdup( [[NSString stringWithFormat:@"%@:%@@%@/%@", username, password, hostname, number] UTF8String] );
	iax_call( session, [cidNumber UTF8String], [cidName UTF8String], ich, NULL, 0, AST_FORMAT_SPEEX, AST_FORMAT_ULAW | AST_FORMAT_SPEEX );
	free( ich );
		
	call = [[MMIAXCall alloc] initWithSession:session callDelegate:callDelegate iax:self];
}

-(void) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate
{
	struct iax_session *oldSession = session;
	session = NULL;
	iax_unregister( oldSession, [hostname UTF8String], [username UTF8String], [password UTF8String], NULL );
	iax_set_will_destroy_session_handler( oldSession, NULL, NULL );
	iax_session_destroy( &oldSession );

	session = callingSession;
	iax_set_will_destroy_session_handler( session, willDestroySessionCallback, self );
	iax_answer( session );
	call = [[MMIAXCall alloc] initWithFormat:callingFormat session:session callDelegate:callDelegate iax:self];
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
			if ( ![call handleEvent:event] )
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

-(void) reregister
{
	struct iax_session *oldSession = session;
	session = NULL;
	iax_unregister( oldSession, [hostname UTF8String], [username UTF8String], [password UTF8String], NULL );
	iax_session_destroy( &oldSession );
}

@end
