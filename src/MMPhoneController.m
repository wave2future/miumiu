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
#import "MMDataPushToPullAdapter.h"
#import "MMComfortNoiseInjector.h"
#import "MMMuteInjector.h"
#import "MMDataPipeChain.h"
#import "MMCall.h"
#import "MMCodec.h"

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
	pushToPullAdapter = [[MMDataPushToPullAdapter alloc] initWithBufferCapacity:320*4];
	postClockDataProcessorChain = [[MMDataPipeChain alloc] init];
	comfortNoiseInjector = [[MMComfortNoiseInjector alloc] init];
	muteInjector = [[MMMuteInjector alloc] init];

	[pushToPullAdapter connectToTarget:postClockDataProcessorChain];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain connectToTarget:audioController];

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
	[pushToPullAdapter release];
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
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyPhoneViewThatCallDidBegin:) onThread:[NSThread mainThread] withObject:_call waitUntilDone:NO];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:ringtoneInjector];
}

-(void) call:(MMCall *)_ didAnswerWithEncoder:(MMCodec *)encoder decoder:(MMCodec *)decoder
{
	[audioController connectToTarget:muteInjector];
	[muteInjector connectToTarget:encoder];
	[encoder connectToTarget:call];
	
	[call connectToTarget:decoder];
	[decoder connectToTarget:pushToPullAdapter];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:busyInjector];
}

-(void) callDidFail:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:fastBusyInjector];
}

-(void) callDidEnd:(MMCall *)_call
{
	[audioController disconnectFromTarget];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];

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
