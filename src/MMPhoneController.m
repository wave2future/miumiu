//
//  MMPhoneController.m
//  MiuMiu
//
//  Created by Peter Zion on 12/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneController.h"
#import "MMIAX.h"
#import "MMLoopback.h"
#import "MMRingInjector.h"
#import "MMBusyInjector.h"
#import "MMFastBusyInjector.h"
#import "MMAudioController.h"
#import "MMDTMFInjector.h"
#import "MMClock.h"
#import "MMComfortNoiseInjector.h"
#import "MMMuteInjector.h"
#import "MMDataProcessorChain.h"
#import "MMCall.h"

#define MM_PHONE_CONTROLLER_LOOPBACK

@implementation MMPhoneController

-(void) main
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	audioController = [[MMAudioController alloc] init];
	
#ifdef MM_PHONE_CONTROLLER_LOOPBACK
	protocol = [[MMLoopback alloc] initWithProtocolDelegate:self];
#else
	protocol = [[MMIAX alloc] initWithProtocolDelegate:self];
#endif

	ringtoneInjector = [[MMRingInjector alloc] init];
	busyInjector = [[MMBusyInjector alloc] init];
	fastBusyInjector = [[MMFastBusyInjector alloc] init];
	dtmfInjector = [[MMDTMFInjector alloc] initWithSamplingFrequency:8000];
	clock = [[MMClock alloc] initWithSamplesPerTick:160 samplingFrequency:8000];
	postClockDataProcessorChain = [[MMDataProcessorChain alloc] init];
	comfortNoiseInjector = [[MMComfortNoiseInjector alloc] init];
	muteInjector = [[MMMuteInjector alloc] init];

	[clock connectToConsumer:postClockDataProcessorChain];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain connectToConsumer:audioController];

	while ( ![self isCancelled]
		&& [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
		;

	[autoreleasePool release];
}

-(void) dealloc
{
	[muteInjector release];
	[comfortNoiseInjector release];
	[postClockDataProcessorChain release];
	[clock release];
	[dtmfInjector release];
	[fastBusyInjector release];
	[busyInjector release];
	[ringtoneInjector release];
	[protocol release];
	[audioController release];
	[super dealloc];
}

-(void) internalBeginCallWithNumber:(NSString *)number
{
	call = [[protocol beginCallWithNumber:number callDelegate:self] retain];
}

-(void) view:(MMPhoneView *)view requestedBeginCallWithNumber:(NSString *)number
{
	[self performSelector:@selector(internalBeginCallWithNumber:) onThread:self withObject:number waitUntilDone:NO];
}

-(void) internalPressedDTMF:(NSString *)dtmf
{
	[call sendDTMF:dtmf];
	[dtmfInjector digitPressed:dtmf];
}

-(void) view:(MMPhoneView *)view pressedDTMF:(NSString *)dtmf
{
	[self performSelector:@selector(internalPressedDTMF:) onThread:self withObject:dtmf waitUntilDone:NO];
}

-(void) internalReleasedDTMF:(NSString *)dtmf
{
	[dtmfInjector digitReleased:dtmf];
}

-(void) view:(MMPhoneView *)view releasedDTMF:(NSString *)dtmf
{
	[self performSelector:@selector(internalReleasedDTMF:) onThread:self withObject:dtmf waitUntilDone:NO];
}

-(void) internalMuted
{
	[muteInjector mute];
}

-(void) viewMuted:(MMPhoneView *)view
{
	[self performSelector:@selector(internalMuted) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) internalUnmuted
{
	[muteInjector unmute];
}

-(void) viewUnmuted:(MMPhoneView *)view
{
	[self performSelector:@selector(internalUnmuted) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) internalEndCall:(id)_
{
	[call end];
}

-(void) viewRequestedEndCall:(MMPhoneView *)view
{
	[self performSelector:@selector(internalEndCall:) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBegin:(MMCall *)call
{
	[phoneView didBeginCall];
}

-(void) callDidBegin:(MMCall *)_call
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyPhoneViewThatCallDidBegin:) onThread:[NSThread mainThread] withObject:_call waitUntilDone:NO];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:ringtoneInjector];
}

-(void) call:(MMCall *)_ didAnswerWithEncoder:(MMCodec *)encoder decoder:(MMCodec *)decoder
{
	[audioController connectToConsumer:muteInjector];
	[muteInjector connectToConsumer:encoder];
	[encoder connectToConsumer:call];
	
	[call connectToConsumer:decoder];
	[decoder connectToConsumer:clock];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:busyInjector];
}

-(void) callDidFail:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:fastBusyInjector];
}

-(void) callDidEnd:(MMCall *)_call
{
	[audioController disconnect];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];

	[call release];
	call = nil;
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidEnd) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidEnd
{
	[phoneView didEndCall];
}

@synthesize phoneView;

@end
