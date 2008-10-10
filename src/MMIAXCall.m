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
		iax_call( session, [iax.cidNumber UTF8String], [iax.cidName UTF8String], ich, NULL, 0, AST_FORMAT_SPEEX, AST_FORMAT_SPEEX );
		free( ich );
	}
	return self;
}

-(void) dealloc
{
	[iax unregisterIAXCall:self withSession:session];
	iax_destroy( session );
	
	[iax release];
	
	[super dealloc];
}

-(void) consumeData:(void *)data ofSize:(unsigned)size
{
	iax_send_voice( session, AST_FORMAT_SPEEX, data, size, size/2 );
}

-(void) sendDTMF:(NSString *)dtmf
{
	iax_send_dtmf( session, *[dtmf UTF8String] );
}

-(void) end
{
	iax_hangup( session, "later!" );	
	[delegate callDidEnd:self];
}

-(void) handleEvent:(struct iax_event *)event
{
	switch ( event->etype )
	{
		case IAX_EVENT_ACCEPT:
			[delegate callDidBegin:self];
			break;
		case IAX_EVENT_RINGA:
			[delegate callDidBeginRinging:self];
			break;
		case IAX_EVENT_ANSWER:
			[delegate callDidAnswer:self];
			break;
		case IAX_EVENT_VOICE:
			[self produceData:event->data ofSize:event->datalen];
			break;
		case IAX_EVENT_HANGUP:
			[delegate callDidEnd:self];
			break;
	}
}

@end
