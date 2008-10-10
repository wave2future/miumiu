//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMIAX.h"

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
		hostname = [@"lickmypony.com" retain];
		username = [@"miumiu" retain];
		password = [@"snowdog1" retain];
		cidName = [@"Peter Zion" retain];
		cidNumber = [@"5146515041" retain];
		
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

		regSession = iax_session_new();
		
		iax_register( regSession, [hostname UTF8String], [username UTF8String], [password UTF8String], 1 );
	}
	return self;
}

-(void) dealloc
{
	iax_destroy( regSession );
	// [pzion 20081009] This doesn't actually appear to be present in libiax..
	//iax_end();
	[password release];
	[username release];
	[hostname release];
	[cidNumber release];
	[cidName release];
	[super dealloc];
}

-(void) beginCall:(NSString *)number
{
	connected = NO;

	callSession = iax_session_new();
	
	NSString *ich = [NSString stringWithFormat:@"%@:%@@%@/%@", username, password, hostname, number];
	iax_call( callSession, [cidNumber UTF8String], [cidName UTF8String], (char *)[ich UTF8String], NULL, 0, AST_FORMAT_SPEEX, AST_FORMAT_SPEEX );
}

-(void) endCall
{
	iax_hangup( callSession, "later!" );
	
	iax_destroy( callSession );
}

-(void) socketCallbackCalled
{
	struct iax_event *event;
	while ( event = iax_get_event( 0 ) )
	{
		switch ( event->etype )
		{
			case IAX_EVENT_VOICE:
				[self produceData:event->data ofSize:event->datalen];
				break;
			case IAX_EVENT_ANSWER:
				connected = YES;
				break;
		}
		
		iax_event_free( event );
	}
}

-(void) consumeData:(void *)data ofSize:(unsigned)size
{
	if ( connected )
		iax_send_voice( callSession, AST_FORMAT_SPEEX, data, size, size/2 );
}

-(void) sendDTMF:(NSString *)dtmf
{
	if ( connected )
		iax_send_dtmf( callSession, *[dtmf UTF8String] );
}

@synthesize delegate;

@end
