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

#pragma mark Private

-(void) answerCall
{
	[delegate callDidAnswer:self];
}

-(void) startRinging
{
	[delegate callDidBeginRinging:self];
	[self performSelector:@selector(answerCall) withObject:nil afterDelay:1.0];
}

#pragma mark Initialization

-(id) initWithCallDelegate:(id <MMCallDelegate>)_delegate
{
	if ( self = [super init] )
	{
		delegate = [_delegate retain];
		[delegate callDidBegin:self];
		[self performSelector:@selector(startRinging) withObject:nil afterDelay:0.5];
	}
	return self;
}

-(void) dealloc
{
	[delegate release];
	[super dealloc];
}

#pragma mark MMSampleConsumer

-(void) reset
{
	// [pzion 20090308] Don't loop back resets, just data
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	[super consumeSamples:samples count:count];
}

#pragma mark MMCall

-(void) sendDTMF:(NSString *)dtmf
{
}

-(void) end
{
	[delegate callDidEnd:self];
}

@end
