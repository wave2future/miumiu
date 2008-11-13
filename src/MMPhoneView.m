//
//  MMPhoneView.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneView.h"
#import "MMPhoneButton.h"
#import "MMPhoneTextField.h"
#import "MMPhoneLabel.h"
#import "MMPhoneSlider.h"
#import "MMPhoneAlert.h"
#import "MMPhoneLevel.h"
#import "MMUIHelpers.h"
#import "MMWindow.h"

static NSString *beginCallTitle = @"Call", *endCallTitle = @"End", *clearNumberTitle = @"Clear";
static NSString *muteTitle = @"Mute", *unmuteTitle = @"Unmute";

#define NUM_DIGITS 12
static NSString *digitTitles[NUM_DIGITS] = { @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#" };

@implementation MMPhoneView

-(MMPhoneButton *) buttonWithTitle:(NSString *)title
{
	MMPhoneButton *button = [[[MMPhoneButton alloc] initWithTitle:title] autorelease];
	[button setPressTarget:self action:@selector(buttonPressed:)];
	[button setReleaseTarget:self action:@selector(buttonReleased:)];
	[self addSubview:button.view];
	return button;
}

-(void) layoutSubviews
{
	MMRect bounds = self.bounds;
	MMFloat top = MMRectGetMinY(bounds);
	MMFloat bottom = MMRectGetMaxY(bounds);
	
	statusLabel.frame = MMRectMake( MMRectGetMinX(bounds), top, MMRectGetWidth(bounds), 20 );
	top = MMRectGetMaxY( statusLabel.frame );
	numberTextField.frame = MMRectMake( MMRectGetMinX(bounds), top, MMRectGetWidth(bounds), 30 );
	top = MMRectGetMaxY( numberTextField.frame );
	
	MMRect controlBounds = MMRectMake( MMRectGetMinX(bounds), top, MMRectGetWidth(bounds), 40 );
	MMRect controlButtonFrames[2];
	MMSubdivideRectEvenly( controlBounds, 1, 2, controlButtonFrames );
	beginCallButton.frame = controlButtonFrames[0];
	endCallButton.frame = controlButtonFrames[0];
	clearNumberButton.frame = controlButtonFrames[1];
	muteButton.frame = controlButtonFrames[1];
	unmuteButton.frame = controlButtonFrames[1];
	top = MMRectGetMaxY( unmuteButton.frame );
	
#ifdef MACOSX
	playbackLevelSlider.frame = MMRectMake( MMRectGetMinX(bounds), bottom-20, MMRectGetWidth(bounds), 20 );
	bottom = MMRectGetMinY( playbackLevelSlider.frame );
#endif

	MMRect levelBounds = MMRectMake( MMRectGetMinX(bounds), bottom-20, MMRectGetWidth(bounds), 20 );
	MMRect levelFrames[2];
	MMSubdivideRectEvenly( levelBounds, 1, 2, levelFrames );
	outputLevelMeter.frame = levelFrames[0];
	inputLevelMeter.frame = levelFrames[1];
	bottom = MMRectGetMinY( inputLevelMeter.frame );

	MMRect digitBounds = MMRectMake( MMRectGetMinX(bounds), top, MMRectGetWidth(bounds), bottom-top );
	MMRect digitButtonBounds[12];
	MMSubdivideRectEvenly( digitBounds, 4, 3, digitButtonBounds );
	for ( unsigned row=0; row<4; ++row )
	{
		for ( unsigned col=0; col<3; ++col )
		{
			unsigned i = row*3 + col;
		
			MMPhoneButton *digitButton = [digitButtons objectAtIndex:i];
			digitButton.frame = digitButtonBounds[i];
		}
	}
}

-(void) updateButtonStates
{
	BOOL haveDigits = [numberTextField.text length] > 0;
	
	beginCallButton.enabled = !inCall && haveDigits;
	endCallButton.hidden = !inCall;

	clearNumberButton.enabled = haveDigits;
	clearNumberButton.hidden = inCall;
	muteButton.enabled = !muted;
	muteButton.hidden = muted || !inCall;
	unmuteButton.enabled = muted;
	unmuteButton.hidden = !muted || !inCall;
}

-(id) initWithFrame:(MMRect)frame number:(NSString *)number inProgress:(BOOL)inProgress;
{
	if ( self = [super initWithFrame:frame] )
	{
		statusLabel = [[MMPhoneLabel alloc] init];
		[self addSubview:statusLabel.view];
		
#ifdef MACOSX
		playbackLevelSlider = [[MMPhoneSlider alloc] init];
		playbackLevelSlider.delegate = self;
		playbackLevelSlider.value = 1.0;
		[self addSubview:playbackLevelSlider.view];
#endif
		
		outputLevelMeter = [[MMPhoneLevel alloc] init];
		[self addSubview:outputLevelMeter.view];
		
		inputLevelMeter = [[MMPhoneLevel alloc] init];
		[self addSubview:inputLevelMeter.view];
		
		numberTextField = [[MMPhoneTextField alloc] init];
		numberTextField.delegate = self;
		numberTextField.text = number;
		[self addSubview:numberTextField.view];

		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardAppearing:) 
							   name:@"UIKeyboardWillShowNotification" 
							   object:nil];
		
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardDisappearing:) 
							   name:@"UIKeyboardWillHideNotification" 
							   object:nil];
		
		beginCallButton = [[self buttonWithTitle:beginCallTitle] retain];
		endCallButton = [[self buttonWithTitle:endCallTitle] retain];
		clearNumberButton = [[self buttonWithTitle:clearNumberTitle] retain];
		muteButton = [[self buttonWithTitle:muteTitle] retain];
		unmuteButton = [[self buttonWithTitle:unmuteTitle] retain];
	
		digitButtons = [[NSMutableArray alloc] initWithCapacity:12];
		for ( int i=0; i<NUM_DIGITS; ++i )
			[digitButtons addObject:[self buttonWithTitle:digitTitles[i]]];
		
		[self updateButtonStates];
		[self layoutSubviews];
	}
	return self;
}

-(void) dealloc
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	
	[incommingAlert release];
	[digitButtons release];
	[unmuteButton release];
	[muteButton release];
	[endCallButton release];
	[beginCallButton release];
	[clearNumberButton release];
	[numberTextField release];
	[inputLevelMeter release];
	[outputLevelMeter release];
#ifdef MACOSX
	[playbackLevelSlider release];
#endif
	[statusLabel release];
	[super dealloc];
}

#ifdef MACOSX
-(BOOL) isFlipped
{
	return YES;
}
#endif

-(void) buttonPressed:(MMPhoneButton *)button
{
	if ( button == beginCallButton )
		;
	else if ( button == endCallButton )
		;
	else if ( button == clearNumberButton )
		;
	else if ( button == muteButton )
		;
	else if ( button == unmuteButton )
		;
	else
	{
		NSString *digit = button.title;

		NSString *oldText = numberTextField.text;
		if ( oldText != nil )
			numberTextField.text = [NSString stringWithFormat:@"%@%@", oldText, digit];
		else
			numberTextField.text = digit;

		[self updateButtonStates];

		[delegate view:self pressedDTMF:digit];
	}
}

-(void) buttonReleased:(MMPhoneButton *)button
{
	if ( button == beginCallButton )
		[delegate view:self requestedBeginCallWithNumber:numberTextField.text];
	else if ( button == endCallButton )
		[delegate viewRequestedEndCall:self];
	else if ( button == clearNumberButton )
	{
		numberTextField.text = @"";
		beginCallButton.enabled = NO;
		[self updateButtonStates];
	}
	else if ( button == muteButton )
	{
		[delegate viewMuted:self];
		muted = YES;
		[self updateButtonStates];
	}
	else if ( button == unmuteButton )
	{
		[delegate viewUnmuted:self];
		muted = NO;
		[self updateButtonStates];
	}
	else
	{
		NSString *digit = button.title;

		[delegate view:self releasedDTMF:digit];
	}
}

-(void) didBeginCall
{
	inCall = YES;
	[self updateButtonStates];
}

-(void) didEndCall
{
	inCall = NO;
	numberTextField.text = @"";
	[self updateButtonStates];
}

-(void) textFieldDidChange:(MMPhoneTextField *)textField
{
	[self updateButtonStates];
}

-(void) keyboardDisappearing:(NSNotification *)note
{
	NSLog(@"Received notification: %@", note);
}

-(void) keyboardAppearing:(NSNotification *)note
{
	NSLog(@"Received notification: %@", note);
}

-(void) callIsBeingReceivedFrom:(NSString *)cidInfo
{
	incommingAlert = [[MMPhoneAlert alloc] initWithWindow:[self window] cidInfo:cidInfo];
	incommingAlert.delegate = self;
	[incommingAlert post];
}

-(void) phoneAlertDidAccept:(MMPhoneAlert *)phoneAlert
{
	[incommingAlert autorelease];
	incommingAlert = nil;
	[delegate viewDidAnswerCall:self];
}

-(void) phoneAlertDidIgnore:(MMPhoneAlert *)phoneAlert
{
	[incommingAlert autorelease];
	incommingAlert = nil;
	[delegate viewDidIgnoreCall:self];
}

-(void) setStatusMessage:(NSString *)statusMessage
{
	statusLabel.text = statusMessage;
}

-(void) phoneSlider:(MMPhoneSlider *)phoneSlider didChangeValueTo:(float)value
{
	[delegate view:self didSetPlaybackLevelTo:value];
}

-(void) inputLevelIs:(float)level
{
	inputLevelMeter.value = level;
}

-(void) outputLevelIs:(float)level
{
	outputLevelMeter.value = level;
}

@synthesize delegate;

@end
