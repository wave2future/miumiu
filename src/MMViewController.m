//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"

//#define LOOPBACK

@implementation MMViewController

-(id) init
{
	if ( self = [super init] )
	{
		speexEncoder = [[MMSpeexEncoder alloc] init];
		speexDecoder = [[MMSpeexDecoder alloc] init];
		
		audioController = [[MMAudioController alloc] init];
		audioController.delegate = self;
		
		iax = [[MMIAX alloc] init];
		iax.delegate = self;
	}
	return self;
}

-(void) dealloc
{
	[view release];
	[iax release];
	[audioController release];
	[speexEncoder release];
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
	[iax beginCall:number];
	
	[speexDecoder start];
	[speexEncoder start];

	encodedBuffer = [[MMCircularBuffer alloc] init];
	decodedBuffer = [[MMCircularBuffer alloc] init];

	[audioController start];

	[view didBeginCall:self];
}

-(void) viewRequestedEndCall:(MMView *)_
{
	[audioController stop];

	[decodedBuffer release];
	[encodedBuffer release];

	[speexEncoder stop];
	[speexDecoder stop];
	
	[iax endCall];
	
	[view didEndCall:self];
}

-(void) audioController:(MMAudioController *)_  recordedToBuffer:(MMCircularBuffer *)buffer
{
	[speexEncoder fromBuffer:buffer toBuffer:encodedBuffer];
#ifdef LOOPBACK
	[speexDecoder fromBuffer:encodedBuffer toBuffer:decodedBuffer];
	[audioController playbackFromBuffer:decodedBuffer];
#else
	[iax playbackFromBuffer:encodedBuffer];
#endif
}

-(void) iax:(MMIAX *)iax recordedAudioToBufer:(MMCircularBuffer *)buffer
{
#ifndef LOOPBACK
	[speexDecoder fromBuffer:buffer toBuffer:decodedBuffer];
	[audioController playbackFromBuffer:decodedBuffer];
#endif
}

@end
