//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"

//#define LOOPBACK_THROUGH_AUDIO
//#define LOOPBACK_THROUGH_SPEEX

#define TAP_FILE_NAME CFSTR("tap")
#define TAP_FILE_TYPE CFSTR("aif")

@implementation MMViewController

@synthesize soundFileURLRef;
@synthesize soundFileObject;

-(id) init
{
	if ( self = [super init] )
	{
		speexEncoder = [[MMSpeexEncoder alloc] init];
		speexDecoder = [[MMSpeexDecoder alloc] init];
		
		audioController = [[MMAudioController alloc] init];
		
		iax = [[MMIAX alloc] init];
		iax.delegate = self;
		
#ifdef LOOPBACK_THROUGH_AUDIO
		[audioController connectToConsumer:audioController];
#else
		[audioController connectToConsumer:speexEncoder];
# ifdef LOOPBACK_THROUGH_SPEEX
		[speexEncoder connectToConsumer:speexDecoder];
# else
		[speexEncoder connectToConsumer:iax];
		[iax connectToConsumer:speexDecoder];
# endif
		[speexDecoder connectToConsumer:audioController];
#endif
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
	AudioServicesDisposeSystemSoundID (self.soundFileObject);
	CFRelease (soundFileURLRef);
}

-(void) loadView
{
	view = [[MMView alloc] initWithNumber:@"" inProgress:NO];
	view.delegate = self;
	self.view = view;
}

- (void) viewDidLoad {
	
	[super viewDidLoad];
	
	// Get the main bundle for the app
	CFBundleRef mainBundle;
	mainBundle = CFBundleGetMainBundle ();
	
	// Get the URL to the sound file to play
	soundFileURLRef  =	CFBundleCopyResourceURL (
												 mainBundle,
												 TAP_FILE_NAME,
												 TAP_FILE_TYPE,
												 NULL
												 );
	
	// Create a system sound object representing the sound file
	AudioServicesCreateSystemSoundID (
									  soundFileURLRef,
									  &soundFileObject
									  );
	
}

-(void) view:(MMView *)_ requestedBeginCallWithNumber:(NSString *)number
{
	if ( [number length] == 0 )
		return;
	
	[iax beginCall:number];
	
	[speexDecoder start];
	[speexEncoder start];

	[audioController start];

	[view didBeginCall:self];
	
	inCall = YES;
}

-(void) view:(MMView *)view pressedDTMF:(NSString *)dtmf
{
	AudioServicesPlaySystemSound (self.soundFileObject);
	if ( inCall )
		[iax sendDTMF:dtmf];
}

-(void) view:(MMView *)view releasedDTMF:(NSString *)dtmf
{
}

-(void) viewRequestedEndCall:(MMView *)_
{
	inCall = NO;
	
	[audioController stop];

	[speexEncoder stop];
	[speexDecoder stop];
	
	[iax endCall];
	
	[view didEndCall:self];
}

@end
