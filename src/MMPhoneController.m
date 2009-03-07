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
#import "MMPreprocessor.h"

//#define MM_PHONE_CONTROLLER_LOOPBACK

@implementation MMPhoneController

-(void) main
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	audioController = [[MMAudioController alloc] init];
	audioController.delegate = self;

#ifdef MM_PHONE_CONTROLLER_LOOPBACK
	protocol = [[MMLoopback alloc] initWithProtocolDelegate:self];
#else
	protocol = [[MMIAX alloc] initWithProtocolDelegate:self];
#endif

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString *server = [userDefaults stringForKey:@"server"];
	NSString *username = [userDefaults stringForKey:@"username"];
	NSString *password = [userDefaults stringForKey:@"password"];
	NSString *cidName = [userDefaults stringForKey:@"cidName"];
	NSString *cidNumber = [userDefaults stringForKey:@"cidNumber"];

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

	NSError *error;
	if ( ![protocol loginWithServer:server
		username:username
		password:password
		cidName:cidName
		cidNumber:cidNumber
		withResultingError:&error] )
	{
		[self performSelector:@selector(notifyPhoneViewThatLoginFailedBecause:)
			onThread:[NSThread mainThread]
			withObject:error
			waitUntilDone:NO];
	}
	else
	{
		[self performSelector:@selector(notifyPhoneViewThatPhoneIsReady)
			onThread:[NSThread mainThread]
			withObject:nil
			waitUntilDone:NO];
	}

	while ( ![self isCancelled]
		&& [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
		;

	[autoreleasePool release];
}

-(void) notifyPhoneViewThatPhoneIsReady
{
	[phoneView setStatusMessage:@"Ready"];
}

-(void) notifyPhoneViewThatLoginFailedBecause:(NSError *)error
{
	[phoneView setStatusMessage:[NSString stringWithFormat:@"Login failed: %@", [error localizedDescription]]];
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

-(void) callDidBegin:(MMCall *)call
{
	mCall = [call retain];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyPhoneViewThatCallDidBegin:) onThread:[NSThread mainThread] withObject:call waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBegin:(MMCall *)call
{
	[phoneView setStatusMessage:@"Connecting"];
	[phoneView didBeginCall];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:ringtoneInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidBeginRinging) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBeginRinging
{
	[phoneView setStatusMessage:@"Ringing"];
}

-(void) call:(MMCall *)call didAnswerWithEncoder:(MMCodec *)_encoder decoder:(MMCodec *)_decoder
{
	encoder = [_encoder retain];
	decoder = [_decoder retain];
	
	[audioController connectToTarget:muteInjector];
	[muteInjector connectToTarget:encoder];
	[encoder connectToTarget:call];
	[call connectToTarget:decoder];
	[decoder connectToTarget:pushToPullAdapter];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidAnswer) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidAnswer
{
	[phoneView setStatusMessage:@"Connected"];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:busyInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidBusy) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBusy
{
	[phoneView setStatusMessage:@"Busy"];
}

-(void) callDidFail:(MMCall *)_
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:comfortNoiseInjector];
	[postClockDataProcessorChain pushDataPipeOntoFront:fastBusyInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidFail) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidFail
{
	[phoneView setStatusMessage:@"Call failed"];
}

-(void) callDidEnd:(MMCall *)_call
{
	[audioController disconnectFromTarget];
	
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];

	[audioController disconnectFromTarget];
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
	[phoneView setStatusMessage:@"Call finished"];
	[phoneView didEndCall];
}

-(void) protocol:(MMProtocol *)_protocol isReceivingCallFrom:(NSString *)cidInfo
{
	if ( mCall != nil )
		[protocol ignoreCall];
	else
	{
		[postClockDataProcessorChain zap];
		[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];
		[postClockDataProcessorChain pushDataPipeOntoFront:ringtoneInjector];

		[self performSelector:@selector(notifyPhoneViewThatCallIsBeingReceivedFrom:) onThread:[NSThread mainThread] withObject:cidInfo waitUntilDone:NO];
	}
}

-(void) notifyPhoneViewThatCallIsBeingReceivedFrom:(NSString *)cidInfo
{
	[phoneView setStatusMessage:[NSString stringWithFormat:@"Incomming call from %@", cidInfo]];
	[phoneView callIsBeingReceivedFrom:cidInfo];
}

-(void) internalAnswerCall
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];

	[protocol answerCallWithCallDelegate:self];
}

-(void) internalIgnoreCall
{
	[postClockDataProcessorChain zap];
	[postClockDataProcessorChain pushDataPipeOntoFront:dtmfInjector];

	[protocol ignoreCall];
}

-(void) viewDidAnswerCall:(MMPhoneView *)view
{
	[self performSelector:@selector(internalAnswerCall) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) viewDidIgnoreCall:(MMPhoneView *)view
{
	[phoneView setStatusMessage:@"Ignored call"];
	[self performSelector:@selector(internalIgnoreCall) onThread:self withObject:nil waitUntilDone:NO];
}

-(void) view:(MMPhoneView *)view didSetPlaybackLevelTo:(float)playbackLevel
{
	[self performSelector:@selector(internalSetPlaybackLevelTo:) onThread:self withObject:[NSNumber numberWithFloat:playbackLevel] waitUntilDone:NO];
}	

-(void) internalSetPlaybackLevelTo:(NSNumber *)playbackLevel
{
	[audioController setPlaybackLevelTo:[playbackLevel floatValue]];
}

-(void) audioController:(MMAudioController *)audioController
	inputLevelIs:(float)level
{
	[self performSelector:@selector(notifyPhoneViewThatInputLevelIs:) onThread:[NSThread mainThread] withObject:[NSNumber numberWithFloat:level] waitUntilDone:NO];
}

-(void) notifyPhoneViewThatInputLevelIs:(NSNumber *)level
{
	[phoneView inputLevelIs:[level floatValue]];
}

-(void) audioController:(MMAudioController *)audioController
	outputLevelIs:(float)level
{
	[self performSelector:@selector(notifyPhoneViewThatOutputLevelIs:) onThread:[NSThread mainThread] withObject:[NSNumber numberWithFloat:level] waitUntilDone:NO];
}

-(void) notifyPhoneViewThatOutputLevelIs:(NSNumber *)level
{
	[phoneView outputLevelIs:[level floatValue]];
}

@synthesize phoneView;

@end
