//
//  MMPhoneController.m
//  MiuMiu
//
//  Created by Peter Zion on 12/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneController.h"
#import "MMRingInjector.h"
#import "MMBusyInjector.h"
#import "MMFastBusyInjector.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMAudioController.h"
#import "MMDTMFInjector.h"
#import "MMNullProducer.h"
#import "MMComfortNoiseInjector.h"

//#define LOOPBACK_THROUGH_CODECS

@implementation MMPhoneController

-(void) main
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	audioController = [[MMAudioController alloc] init];
	audioController.delegate = self;
	
	iax = [[MMIAX alloc] init];
	iax.delegate = self;

	ringtoneInjector = [[MMRingInjector alloc] init];
	busyInjector = [[MMBusyInjector alloc] init];
	fastBusyInjector = [[MMFastBusyInjector alloc] init];
	dtmfInjector = [[MMDTMFInjector alloc] initWithSamplingFrequency:8000];
	nullProducer = [[MMNullProducer alloc] initWithSamplesPerPacket:160 samplingFrequency:8000];
	comfortNoiseInjector = [[MMComfortNoiseInjector alloc] init];
	
	[dtmfInjector connectToConsumer:audioController];
	[nullProducer connectToConsumer:dtmfInjector];

	while ( ![self isCancelled]
		&& [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
		;

	[autoreleasePool release];
}

-(void) dealloc
{
	[comfortNoiseInjector release];
	[nullProducer release];
	[dtmfInjector release];
	[fastBusyInjector release];
	[busyInjector release];
	[ringtoneInjector release];
	[iax release];
	[audioController release];
	[super dealloc];
}

-(void) internalBeginCallWithNumber:(NSString *)number
{
	call = [[iax beginCall:number] retain];
	call.delegate = self;
}

-(void) beginCallWithNumber:(NSString *)number
{
	[self performSelector:@selector(internalBeginCallWithNumber:) onThread:self withObject:number waitUntilDone:NO];
}

-(void) internalPressedDTMF:(NSString *)dtmf
{
	[call sendDTMF:dtmf];
	[dtmfInjector digitPressed:dtmf];
}

-(void) pressedDTMF:(NSString *)dtmf
{
	[self performSelector:@selector(internalPressedDTMF:) onThread:self withObject:dtmf waitUntilDone:NO];
}

-(void) internalReleasedDTMF:(NSString *)dtmf
{
	[dtmfInjector digitReleased:dtmf];
}

-(void) releasedDTMF:(NSString *)dtmf
{
	[self performSelector:@selector(internalReleasedDTMF:) onThread:self withObject:dtmf waitUntilDone:NO];
}

-(void) internalEndCall:(id)_
{
	[call end];
}

-(void) endCall
{
	[self performSelector:@selector(internalEndCall:) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) notifyDelegateThatCallDidBegin:(MMCall *)call
{
	[delegate phoneControllerDidBeginCall:self];
}

-(void) callDidBegin:(MMCall *)_call
{
	[audioController resetOutputDelay];

	[comfortNoiseInjector connectToConsumer:dtmfInjector];
	[nullProducer connectToConsumer:comfortNoiseInjector];
	[self performSelector:@selector(notifyDelegateThatCallDidBegin:) onThread:[NSThread mainThread] withObject:_call waitUntilDone:NO];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[audioController resetOutputDelay];

	[ringtoneInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:ringtoneInjector];
}

-(void) call:(MMCall *)_ didAnswerWithUseSpeex:(BOOL)useSpeex
{
	[audioController resetOutputDelay];

	[nullProducer disconnect];
	[ringtoneInjector disconnect];

	if ( useSpeex )
	{
		encoder = [[MMSpeexEncoder alloc] init];
		decoder = [[MMSpeexDecoder alloc] init];
	}
	else
	{
		encoder = [[MMULawEncoder alloc] init];
		decoder = [[MMULawDecoder alloc] init];
	}
	
	[audioController connectToConsumer:encoder];
#ifdef LOOPBACK_THROUGH_CODECS
	[encoder connectToConsumer:decoder];
#else
	[encoder connectToConsumer:call];
	[call connectToConsumer:decoder];
#endif
	[decoder connectToConsumer:comfortNoiseInjector];

	[audioController startRecording];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[audioController resetOutputDelay];

	[busyInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:busyInjector];
}

-(void) callDidFail:(MMCall *)_
{
	[audioController resetOutputDelay];

	[fastBusyInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:fastBusyInjector];
}

-(void) callDidEnd:(MMCall *)_call
{
	[audioController stopRecording];
	
	[comfortNoiseInjector disconnect];

	[ringtoneInjector disconnect];
	[busyInjector disconnect];
	[fastBusyInjector disconnect];
	
	[decoder disconnect];
	[call disconnect];
	[encoder disconnect];
	[audioController disconnect];
	
	[encoder release];
	encoder = nil;
	[decoder release];
	decoder = nil;
	
	[call release];
	call = nil;
	
	[nullProducer connectToConsumer:dtmfInjector];
	
	[self performSelector:@selector(notifyDelegateThatCallDidEnd:) onThread:[NSThread mainThread] withObject:_call waitUntilDone:NO];
}

-(void) notifyDelegateThatCallDidEnd:(MMCall *)call
{
	[delegate phoneControllerDidEndCall:self];
}

-(void) audioController:(MMAudioController *)audioController outputDelayIsNow:(float)outputDelay
{
	outputDelayToPassToMainThread = outputDelay;
	[self performSelector:@selector(notifyDelegateThatOutputDelayHasChanged) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyDelegateThatOutputDelayHasChanged
{
	[delegate phoneController:self outputDelayIsNow:outputDelayToPassToMainThread];
}

@synthesize delegate;

@end
