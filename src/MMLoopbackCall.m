//
//  MMLoopbackCall.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMLoopbackCall.h"
#import "MMLoopback.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMCallDelegate.h"

@implementation MMLoopbackCall

-(void) answerCall
{
	[delegate call:self didAnswerWithEncoder:[MMSpeexEncoder codec] decoder:[MMSpeexDecoder codec]];
}

-(void) startRinging
{
	[delegate callDidBeginRinging:self];
	[self performSelector:@selector(answerCall) withObject:nil afterDelay:1.0];
}

-(id) initWithCallDelegate:(id <MMCallDelegate>)_delegate
{
	if ( self = [super initWithCallDelegate:_delegate] )
	{
		[delegate callDidBegin:self];
		[self performSelector:@selector(startRinging) withObject:nil afterDelay:0.5];
	}
	return self;
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[self pushData:data ofSize:size numSamples:numSamples];
}

-(void) sendDTMF:(NSString *)dtmf
{
}

-(void) end
{
	[delegate callDidEnd:self];
}

@end
