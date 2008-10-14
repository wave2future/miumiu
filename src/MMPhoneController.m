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
#import "MMAudioController.h"
#import "MMDTMFInjector.h"
#import "MMClock.h"
#import "MMComfortNoiseInjector.h"
#import "MMDataProcessorChain.h"

//#define LOOPBACK_THROUGH_CODECS

@implementation MMPhoneController

-(void) main
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	audioController = [[MMAudioController alloc] init];
	
	iax = [[MMIAX alloc] init];
	iax.delegate = self;

	ringtoneInjector = [[MMRingInjector alloc] init];
	busyInjector = [[MMBusyInjector alloc] init];
	fastBusyInjector = [[MMFastBusyInjector alloc] init];
	dtmfInjector = [[MMDTMFInjector alloc] initWithSamplingFrequency:8000];
	clock = [[MMClock alloc] initWithSamplesPerTick:160 samplingFrequency:8000];
	postClockDataProcessorChain = [[MMDataProcessorChain alloc] init];
	comfortNoiseInjector = [[MMComfortNoiseInjector alloc] init];

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
	[comfortNoiseInjector release];
	[postClockDataProcessorChain release];
	[clock release];
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
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataProcessorOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataProcessorOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyDelegateThatCallDidBegin:) onThread:[NSThread mainThread] withObject:_call waitUntilDone:NO];
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
	[audioController connectToConsumer:encoder];
#ifdef LOOPBACK_THROUGH_CODECS
	[encoder connectToConsumer:decoder];
#else
	[encoder connectToConsumer:call];
	[call connectToConsumer:decoder];
#endif
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
	
	[self performSelector:@selector(notifyDelegateThatCallDidEnd) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyDelegateThatCallDidEnd
{
	[delegate phoneControllerDidEndCall:self];
}

@synthesize delegate;

@end
