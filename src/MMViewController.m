//
//  MiuMiuAppDelegate.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "MMViewController.h"

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
	call = [[iax beginCall:number] retain];
	call.delegate = self;
}

-(void) view:(MMView *)view pressedDTMF:(NSString *)dtmf
{
	AudioServicesPlaySystemSound (self.soundFileObject);
	[call sendDTMF:dtmf];
}

-(void) view:(MMView *)view releasedDTMF:(NSString *)dtmf
{
}

-(void) viewRequestedEndCall:(MMView *)_
{
	[call end];
}

-(void) callDidBegin:(MMCall *)call
{
	[view didBeginCall:self];
}

-(void) callDidBeginRinging:(MMCall *)call
{
}

-(void) callDidEndRinging:(MMCall *)call
{
}

-(void) callDidAnswer:(MMCall *)_
{
	[audioController connectToConsumer:speexEncoder];
	[speexEncoder connectToConsumer:call];
	[call connectToConsumer:speexDecoder];
	[speexDecoder connectToConsumer:audioController];

	[speexDecoder start];
	[speexEncoder start];
	[audioController start];
}

-(void) callDidEnd:(MMCall *)_
{
	[audioController stop];
	[speexEncoder stop];
	[speexDecoder stop];
	
	[speexDecoder disconnect];
	[call disconnect];
	[speexEncoder disconnect];
	[audioController disconnect];
	
	[call release];
	call = nil;
	
	[view didEndCall:self];
}

@end
