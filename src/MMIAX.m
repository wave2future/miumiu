//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMIAX.h"
#import "MMIAXCall.h"

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

-(id) init
{
	if ( self = [super init] )
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

-(MMCall *) beginCall:(NSString *)number
{
	if ( numCalls >= MM_IAX_MAX_NUM_CALLS )
		return nil;
		
	return [[[MMIAXCall alloc] initWithNumber:number iax:self] autorelease];
}

-(void) socketCallbackCalled
{
	struct iax_event *event;
	while ( event = iax_get_event( 0 ) )
	{
		if ( event->etype != IAX_EVENT_NULL )
		{
			if ( event->session == session )
			{
				switch ( event->etype )
				{
				}
			}
			else
			{
				for ( unsigned i=0; i<numCalls; ++i )
				{
					if ( calls[i].session == event->session )
					{
						[calls[i].iaxCall handleEvent:event];
						break;
					}
				}
			}
		}
		
		iax_event_free( event );
	}
}

@end
