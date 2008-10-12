//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"
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

@implementation MMViewController

-(id) init
{
	if ( self = [super init] )
	{
		audioController = [[MMAudioController alloc] init];
		
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
	}
	return self;
}

-(void) dealloc
{
	[comfortNoiseInjector release];
	[nullProducer release];
	[dtmfInjector release];
	[fastBusyInjector release];
	[busyInjector release];
	[ringtoneInjector release];
	[view release];
	[iax release];
	[audioController release];
	[super dealloc];
}

-(void) loadView
{
	view = [[MMView alloc] initWithNumber:@"" inProgress:NO];
	view.delegate = self;
	self.view = view;
}

-(void) view:(MMView *)_ requestedBeginCallWithNumber:(NSString *)number
{
	call = [[iax beginCall:number] retain];
	call.delegate = self;
}

-(void) view:(MMView *)view pressedDTMF:(NSString *)dtmf
{
	[call sendDTMF:dtmf];
	[dtmfInjector digitPressed:dtmf];
}

-(void) view:(MMView *)view releasedDTMF:(NSString *)dtmf
{
	[dtmfInjector digitReleased:dtmf];
}

-(void) viewRequestedEndCall:(MMView *)_
{
	[call end];
}

-(void) callDidBegin:(MMCall *)call
{
	[comfortNoiseInjector connectToConsumer:dtmfInjector];
	[nullProducer connectToConsumer:comfortNoiseInjector];
	
	[view didBeginCall:self];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[ringtoneInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:ringtoneInjector];
}

-(void) call:(MMCall *)_ didAnswerWithUseSpeex:(BOOL)useSpeex
{
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
	[busyInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:busyInjector];
}

-(void) callDidFail:(MMCall *)_
{
	[fastBusyInjector connectToConsumer:comfortNoiseInjector];
	[nullProducer connectToConsumer:fastBusyInjector];
}

-(void) callDidEnd:(MMCall *)_
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
	
	[view didEndCall:self];
}

@end
