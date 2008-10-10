//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"

@implementation MMViewController

-(id) init
{
	if ( self = [super init] )
	{
		speexEncoder = [[MMSpeexEncoder alloc] init];
		speexDecoder = [[MMSpeexDecoder alloc] init];
		
		audioController = [[MMAudioController alloc] init];
		audioController.delegate = self;
	}
	return self;
}

-(void) dealloc
{
	[view release];
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
	[speexDecoder start];
	[speexEncoder start];

	fromDecoderBuffer = [[MMCircularBuffer alloc] init];
	loopbackBuffer = [[MMCircularBuffer alloc] init];

	[audioController start];

	[view didBeginCall:self];
}

-(void) viewRequestedEndCall:(MMView *)_
{
	[audioController stop];

	[loopbackBuffer release];
	[fromDecoderBuffer release];

	[speexEncoder stop];
	[speexDecoder stop];
	
	[view didEndCall:self];
}

#define SPEEX_ENCODE_BUFFER_SIZE 16384

-(void) audioController:(MMAudioController *)_  recordedToBuffer:(MMCircularBuffer *)buffer
{
	[speexEncoder fromBuffer:buffer toBuffer:loopbackBuffer];
	[speexDecoder fromBuffer:loopbackBuffer toBuffer:fromDecoderBuffer];
	[audioController playbackFromBuffer:fromDecoderBuffer];
}

@end
