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
		phoneController = [[MMPhoneController alloc] init];
		phoneController.delegate = self;
		[phoneController start];

		[NSThread setThreadPriority:0.0];
	}
	return self;
}

-(void) dealloc
{
	[phoneController release];
	[view release];
	[super dealloc];
}

-(void) loadView
{
	view = [[MMView alloc] initWithNumber:@"" inProgress:NO];
	view.delegate = self;
	self.view = view;
}

-(void) phoneControllerDidBeginCall:(MMPhoneController *)phoneController
{
	[view didBeginCall];
}

-(void) phoneControllerDidEndCall:(MMPhoneController *)phoneController
{
	[view didEndCall];
}

-(void) view:(MMView *)_ requestedBeginCallWithNumber:(NSString *)number
{
	[phoneController beginCallWithNumber:number];
}

-(void) view:(MMView *)view pressedDTMF:(NSString *)dtmf
{
	[phoneController pressedDTMF:dtmf];
}

-(void) view:(MMView *)view releasedDTMF:(NSString *)dtmf
{
	[phoneController releasedDTMF:dtmf];
}

-(void) viewRequestedEndCall:(MMView *)_
{
	[phoneController endCall];
}

-(void) phoneController:(MMPhoneController *)phoneController outputDelayIsNow:(float)outputDelay
{
	[view outputDelayIsNow:outputDelay];
}

@end
