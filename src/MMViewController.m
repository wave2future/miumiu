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

#define TAP_FILE_NAME CFSTR("tap")
#define TAP_FILE_TYPE CFSTR("aif")

@implementation MMViewController

@synthesize soundFileURLRef;
@synthesize soundFileObject;

-(id) init
{
	if ( self = [super init] )
	{
		audioController = [[MMAudioController alloc] init];
		
		iax = [[MMIAX alloc] init];
		iax.delegate = self;

		ringtoneGenerator = [[MMRingProducer alloc] init];
		busyGenerator = [[MMBusyProducer alloc] init];
		fastBusyGenerator = [[MMFastBusyProducer alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[fastBusyGenerator release];
	[busyGenerator release];
	[ringtoneGenerator release];
	[view release];
	[iax release];
	[audioController release];
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
	[audioController start];

	[view didBeginCall:self];
}

-(void) callDidBeginRinging:(MMCall *)call
{
	[ringtoneGenerator connectToConsumer:audioController];
}

-(void) call:(MMCall *)_ didAnswerWithUseSpeex:(BOOL)useSpeex
{
	[ringtoneGenerator disconnect];

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
	[decoder connectToConsumer:audioController];
}

-(void) callDidReturnBusy:(MMCall *)_
{
	[busyGenerator connectToConsumer:audioController];
}

-(void) callDidFail:(MMCall *)_
{
	[fastBusyGenerator connectToConsumer:audioController];
}

-(void) callDidEnd:(MMCall *)_
{
	[ringtoneGenerator disconnect];
	[busyGenerator disconnect];
	[fastBusyGenerator disconnect];
	
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
