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

//#define MM_PHONE_CONTROLLER_LOOPBACK

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
	[audioController connectToTarget:muteInjector];

	while ( ![self isCancelled]
		&& [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
		;

	[autoreleasePool release];
}

-(void) dealloc
{
	[decoder release];
	[encoder release];
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
	[protocol beginCallWithNumber:number callDelegate:self];
}

-(void) view:(MMPhoneView *)view requestedBeginCallWithNumber:(NSString *)number
{
	[self performSelector:@selector(internalBeginCallWithNumber:) onThread:self withObject:number waitUntilDone:NO];
}

-(void) internalPressedDTMF:(NSString *)dtmf
{
	[mCall sendDTMF:dtmf];
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

-(void) internalEndCall
{
	[mCall end];
}

-(void) viewRequestedEndCall:(MMPhoneView *)view
{
	[self performSelector:@selector(internalEndCall) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBegin:(MMCall *)call
{
	[phoneView didBeginCall];
}

-(void) callDidBegin:(MMCall *)call
{
	mCall = [call retain];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyPhoneViewThatCallDidBegin:) onThread:[NSThread mainThread] withObject:call waitUntilDone:NO];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:ringtoneInjector];
}

-(void) call:(MMCall *)call didAnswerWithEncoder:(MMCodec *)_encoder decoder:(MMCodec *)_decoder
{
	encoder = [_encoder retain];
	decoder = [_decoder retain];
	
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

	[muteInjector disconnectFromTarget];
	[encoder disconnectFromTarget];
	[mCall disconnectFromTarget];
	[decoder disconnectFromTarget];
	
	[decoder release];
	decoder = nil;
	[encoder release];
	encoder = nil;
	
	[mCall release];
	mCall = nil;
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidEnd) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidEnd
{
	[phoneView didEndCall];
}

-(void) protocol:(MMProtocol *)protocol isReceivingCallFrom:(NSString *)cidInfo
{
	[self performSelector:@selector(notifyPhoneViewThatCallIsBeingReceivedFrom:) onThread:[NSThread mainThread] withObject:cidInfo waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallIsBeingReceivedFrom:(NSString *)cidInfo
{
	[phoneView callIsBeingReceivedFrom:cidInfo];
}

-(void) internalAnswerCall
{
	[protocol answerCallWithCallDelegate:self];
}

-(void) internalIgnoreCall
{
	[protocol ignoreCall];
}

-(void) viewDidAnswerCall:(MMPhoneView *)view
{
	[self performSelector:@selector(internalAnswerCall) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) viewDidIgnoreCall:(MMPhoneView *)view
{
	[self performSelector:@selector(internalIgnoreCall) onThread:self withObject:nil waitUntilDone:NO];
}

@synthesize phoneView;

@end
