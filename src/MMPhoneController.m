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
#import "MMComfortNoiseInjector.h"
#import "MMMuteInjector.h"
#import "MMSamplePipeChain.h"
#import "MMCall.h"
#import "MMPreprocessor.h"
#import "MMOnHookSamplePipe.h"
#import <sys/socket.h>
#import <netinet/in.h>

//#define MM_PHONE_CONTROLLER_LOOPBACK

static MMPhoneController *instance;

static void networkReachabilityCallback( SCNetworkReachabilityRef target,
   SCNetworkReachabilityFlags flags,
   void *_phoneController )
{
	[instance handleNetworkReachabilityCallbackWithFlags:flags];
}
   
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

	onHookSamplePipe = [[MMOnHookSamplePipe alloc] init];
	ringtoneInjector = [[MMRingInjector alloc] init];
	busyInjector = [[MMBusyInjector alloc] init];
	fastBusyInjector = [[MMFastBusyInjector alloc] init];
	dtmfInjector = [[MMDTMFInjector alloc] initWithSamplingFrequency:8000];
	comfortNoiseInjector = [[MMComfortNoiseInjector alloc] init];
	muteInjector = [[MMMuteInjector alloc] init];

	callToAudioChain = [[MMSamplePipeChain alloc] init];
	[onHookSamplePipe connectToSampleConsumer:callToAudioChain];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain connectToSampleConsumer:audioController];
	
	audioToCallChain = [[MMSamplePipeChain alloc] init];
	[audioController connectToSampleConsumer:audioToCallChain];
	[audioToCallChain pushDataPipeOntoFront:muteInjector];
	[audioToCallChain connectToSampleConsumer:onHookSamplePipe];
	
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

	networkReachability = SCNetworkReachabilityCreateWithAddress( NULL, (struct sockaddr *)&sin );
	
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags( networkReachability, &flags );
	[self handleNetworkReachabilityCallbackWithFlags:flags];

	instance = self;
	SCNetworkReachabilitySetCallback( networkReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallback, NULL );
	SCNetworkReachabilityScheduleWithRunLoop( networkReachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes );

	while ( ![self isCancelled]
		&& [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
		;

	[autoreleasePool release];
}

-(void) performSelectorOnPhoneView:(SEL)selector
{
	[phoneView performSelector:selector
		onThread:[NSThread mainThread]
		withObject:nil
		waitUntilDone:NO];
}	

-(void) performSelector:(SEL)selector
	onPhoneViewWithObject:(id)object
{
	[phoneView performSelector:selector
		onThread:[NSThread mainThread]
		withObject:object
		waitUntilDone:NO];
}	

-(void) handleNetworkReachabilityCallbackWithFlags:(SCNetworkReachabilityFlags)flags
{
	if ( (flags & kSCNetworkReachabilityFlagsReachable) == 0
		|| (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0 )
	{
		[self performSelector:@selector(setStatusMessage:)
			onPhoneViewWithObject:@"Network unreachable"];
	}
	else
	{
		[self performSelector:@selector(setStatusMessage:)
			onPhoneViewWithObject:@"Connecting..."];
			
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		NSString *server = [userDefaults stringForKey:@"server"];
		NSString *username = [userDefaults stringForKey:@"username"];
		NSString *password = [userDefaults stringForKey:@"password"];
		NSString *cidName = [userDefaults stringForKey:@"cidName"];
		NSString *cidNumber = [userDefaults stringForKey:@"cidNumber"];

		[protocol connectWithServer:server
			username:username
			password:password
			cidName:cidName
			cidNumber:cidNumber];
	}		
}

-(void) protocolConnectSucceeded:(MMProtocol *)protocol
{
	[self performSelector:@selector(setStatusMessage:)
		onPhoneViewWithObject:@"Ready"];
	[self performSelectorOnPhoneView:@selector(didConnect)];
}

-(void) protocol:(MMProtocol *)protocol
	connectFailedWithError:(NSError *)error;
{
	NSString *statusMessage = [NSString stringWithFormat:@"Connect failed: %@", [error localizedDescription]];
	[self performSelector:@selector(setStatusMessage:)
		onPhoneViewWithObject:statusMessage];
}

-(void) dealloc
{
	[muteInjector release];
	[comfortNoiseInjector release];
	[callToAudioChain release];
	[audioToCallChain release];
	[dtmfInjector release];
	[fastBusyInjector release];
	[busyInjector release];
	[ringtoneInjector release];
	[onHookSamplePipe release];
	[protocol release];
	CFRelease( networkReachability );
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

-(void) callDidBegin:(id <MMCall>)call
{
	mCall = [call retain];
	
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain pushDataPipeOntoFront:comfortNoiseInjector];

	[self performSelector:@selector(notifyPhoneViewThatCallDidBegin:) onThread:[NSThread mainThread] withObject:call waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBegin:(MMCall *)call
{
	[phoneView setStatusMessage:@"Connecting"];
	[phoneView didBeginCall];
}

-(void) callDidBeginRinging:(id <MMCall>)call
{
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain pushDataPipeOntoFront:comfortNoiseInjector];
	[callToAudioChain pushDataPipeOntoFront:ringtoneInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidBeginRinging) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBeginRinging
{
	[phoneView setStatusMessage:@"Ringing"];
}

-(void) callDidAnswer:(id <MMCall>)call
{
	[audioToCallChain disconnectFromSampleConsumer];
	[audioToCallChain connectToSampleConsumer:call];
	
	[onHookSamplePipe disconnectFromSampleConsumer];
	[call connectToSampleConsumer:callToAudioChain];

	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain pushDataPipeOntoFront:comfortNoiseInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidAnswer) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidAnswer
{
	[phoneView setStatusMessage:@"Connected"];
}

-(void) callDidReturnBusy:(id <MMCall>)_
{
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain pushDataPipeOntoFront:comfortNoiseInjector];
	[callToAudioChain pushDataPipeOntoFront:busyInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidBusy) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidBusy
{
	[phoneView setStatusMessage:@"Busy"];
}

-(void) callDidFail:(id <MMCall>)_
{
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
	[callToAudioChain pushDataPipeOntoFront:comfortNoiseInjector];
	[callToAudioChain pushDataPipeOntoFront:fastBusyInjector];
	
	[self performSelector:@selector(notifyPhoneViewThatCallDidFail) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

-(void) notifyPhoneViewThatCallDidFail
{
	[phoneView setStatusMessage:@"Call failed"];
}

-(void) callDidEnd:(id <MMCall>)_call
{
	[audioToCallChain disconnectFromSampleConsumer];
	[audioToCallChain connectToSampleConsumer:onHookSamplePipe];
	
	[mCall disconnectFromSampleConsumer];
	[onHookSamplePipe connectToSampleConsumer:callToAudioChain];
	
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];

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
		[callToAudioChain zap];
		[callToAudioChain pushDataPipeOntoFront:dtmfInjector];
		[callToAudioChain pushDataPipeOntoFront:ringtoneInjector];

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
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];

	[protocol answerCallWithCallDelegate:self];
}

-(void) internalIgnoreCall
{
	[callToAudioChain zap];
	[callToAudioChain pushDataPipeOntoFront:dtmfInjector];

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
