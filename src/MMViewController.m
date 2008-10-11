//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"
#import "MMRingProducer.h"
#import "MMBusyProducer.h"
#import "MMFastBusyProducer.h"
#import "MMULawEncoder.h"
#import "MMULawDecoder.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMAudioController.h"
#import "MMDTMFInjector.h"

@implementation MMViewController

-(id) init
{
	if ( self = [super init] )
	{
		audioController = [[MMAudioController alloc] init];
		
		iax = [[MMIAX alloc] init];
		iax.delegate = self;

		ringtoneProducer = [[MMRingProducer alloc] init];
		busyProducer = [[MMBusyProducer alloc] init];
		fastBusyProducer = [[MMFastBusyProducer alloc] init];
		dtmfInjector = [[MMDTMFInjector alloc] initWithSamplingFrequency:8000];
		
		[dtmfInjector connectToConsumer:audioController];
	}
	return self;
}

-(void) dealloc
{
	[dtmfInjector release];
	[fastBusyProducer release];
	[busyProducer release];
	[ringtoneProducer release];
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
	[audioController start];

	[view didBeginCall:self];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[ringtoneProducer connectToConsumer:dtmfInjector];
}

-(void) call:(MMCall *)_ didAnswerWithUseSpeex:(BOOL)useSpeex
{
	[ringtoneProducer disconnect];

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
	[encoder connectToConsumer:call];
	[call connectToConsumer:decoder];
	[decoder connectToConsumer:dtmfInjector];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[busyProducer connectToConsumer:dtmfInjector];
}

-(void) callDidFail:(MMCall *)_
{
	[fastBusyProducer connectToConsumer:dtmfInjector];
}

-(void) callDidEnd:(MMCall *)_
{
	[ringtoneProducer disconnect];
	[busyProducer disconnect];
	[fastBusyProducer disconnect];
	
	[decoder disconnect];
	[call disconnect];
	[encoder disconnect];
	[audioController disconnect];
	
	[encoder release];
	encoder = nil;
	[decoder release];
	decoder = nil;
	
	[audioController stop];

	[call release];
	call = nil;
	
	[view didEndCall:self];
}

@end
