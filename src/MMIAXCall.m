//
//  MMIAXCall.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMIAXCall.h"
#import "MMIAX.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMCallDelegate.h"

@implementation MMIAXCall

#pragma mark Private

-(NSError *) lastIAXError
{
	NSString *errorString;
	if ( *iax_errstr != '\0' )
		errorString = [NSString stringWithCString:iax_errstr];
	else
		errorString = @"Unknown error (bad username or password?)";
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
	NSError *error = [NSError errorWithDomain:@"MiuMiu" code:1 userInfo:userInfo];
	return error;
}

#pragma mark Lifecycle

-(id) initWithSession:(struct iax_session *)_session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax
{
	if ( self = [super init] )
	{
		delegate = [_delegate retain];
	
		iax = [_iax retain];
		
		session = _session;
		
		[delegate callDidBegin:self];
	}
	return self;
}

-(id) initWithFormat:(unsigned)_format session:(struct iax_session *)_session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax
{
	if ( self = [self initWithSession:_session callDelegate:_delegate iax:_iax] )
	{
		format = _format;

		if ( format == AST_FORMAT_SPEEX )
		{
			encoder = [[MMSpeexEncoder alloc] init];
			decoder = [[MMSpeexDecoder alloc] init];
		}
		else
		{
			encoder = [[MMULawEncoder alloc] init];
			decoder = [[MMULawDecoder alloc] init];
		}
		
		[delegate callDidAnswer:self];
	}
	return self;
}

-(void) dealloc
{
	[encoder release];
	[decoder release];
	[iax release];
	[delegate release];
	[super dealloc];
}

#pragma mark Public

-(BOOL) handleEvent:(struct iax_event *)event
{
	switch ( event->etype )
	{
		case IAX_EVENT_ACCEPT:
			wasAccepted = YES;
			format = event->ies.format;
			break;
		case IAX_EVENT_RINGA:
			[delegate callDidBeginRinging:self];
			break;
		case IAX_EVENT_ANSWER:
		{
			if ( format == AST_FORMAT_SPEEX )
			{
				encoder = [[MMSpeexEncoder alloc] init];
				decoder = [[MMSpeexDecoder alloc] init];
			}
			else
			{
				encoder = [[MMULawEncoder alloc] init];
				decoder = [[MMULawDecoder alloc] init];
			}
			[delegate callDidAnswer:self];
		}
		break;
		case IAX_EVENT_VOICE:
			[decoder decodeData:event->data ofSize:event->datalen toTarget:self];
			break;
		case IAX_EVENT_BUSY:
			[delegate callDidReturnBusy:self];
			break;
		case IAX_EVENT_HANGUP:
			// This will be taken care of by the session ending
			break;
		default:
			return NO;
	}
	return YES;
}

#pragma mark MMSampleProducer

-(void) connectToSampleConsumer:(id <MMSampleConsumer>)consumer
{
	[decoder reset];
	[super connectToSampleConsumer:consumer];
}

#pragma mark MMSampleConsumer

-(void) reset
{
	[encoder reset];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	if ( session != NULL )
		[encoder encodeSamples:samples count:count toTarget:self];
}

#pragma mark MMEncoderTarget
		
-(void) encoder:(id <MMEncoder>)encoder
	didEncodeData:(void *)data
	ofSize:(unsigned)size
	correspondingToSamples:(const short *)samples
	count:(unsigned)count
{
	iax_send_voice( session, format, data, size, count );
}

#pragma mark MMDecoderTarget

-(void) decoder:(id <MMDecoder>)decoder
	didDecodeSamples:(short *)samples
	count:(unsigned)count
	fromData:(const void *)data
	ofSize:(unsigned)size
{
	[super consumeSamples:samples count:count];
}

#pragma mark MMCall

-(void) sendDTMF:(NSString *)dtmf
{
	if ( session != NULL )
		iax_send_dtmf( session, *[dtmf UTF8String] );
}

-(void) end
{
	if ( session != NULL )
	{
		struct iax_session *oldSession = session;
		session = NULL;
		iax_hangup( oldSession, NULL );
	}
	if ( wasAccepted )
		[delegate callDidEnd:self];
	else
		[delegate call:self didFailWithError:[self lastIAXError]];
}

@end
