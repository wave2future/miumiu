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
	
	numberTextField.frame = MMRectMake( MMRectGetMinX(bounds), MMRectGetMinY(bounds), MMRectGetWidth(bounds), 60 );

	MMRect controlBounds = MMRectMake( MMRectGetMinX(bounds), MMRectGetMaxY(numberTextField.frame), MMRectGetWidth(bounds), 60 );
	beginCallButton.frame = MMRectMake( MMRectGetMinX(controlBounds), MMRectGetMinY(controlBounds), MMRectGetWidth(controlBounds)/3, MMRectGetHeight(controlBounds) );
	endCallButton.frame = MMRectMake( MMRectGetMaxX(beginCallButton.frame), MMRectGetMinY(controlBounds), MMRectGetWidth(controlBounds)/3, MMRectGetHeight(controlBounds) );
	clearNumberButton.frame = endCallButton.frame;
	muteButton.frame = MMRectMake( MMRectGetMaxX(endCallButton.frame), MMRectGetMinY(controlBounds), MMRectGetMaxX(controlBounds) - MMRectGetMaxX(endCallButton.frame), MMRectGetHeight(controlBounds) );
	unmuteButton.frame = muteButton.frame;
	
	MMRect digitsBounds = MMRectMake( MMRectGetMinX(bounds), MMRectGetMaxY(controlBounds), MMRectGetWidth(bounds), MMRectGetMaxY(bounds) - MMRectGetMaxY(controlBounds) );
	for ( int i=0; i<12; ++i )
	{
		int row = i/3, col = i%3;
		
		MMPhoneButton *digitButton = [digitButtons objectAtIndex:i];
		digitButton.frame = MMRectMake(
			roundf( MMRectGetMinX(digitsBounds) + col * MMRectGetWidth(digitsBounds) / 3 ),
			roundf( MMRectGetMinY(digitsBounds) + row * MMRectGetHeight(digitsBounds) / 4 ),
			roundf( MMRectGetWidth(digitsBounds) / 3 ),
			roundf( MMRectGetHeight(digitsBounds) / 4 ) );
	}
}

-(id) initWithFrame:(MMRect)frame number:(NSString *)number inProgress:(BOOL)inProgress;
{
	if ( self = [super initWithFrame:frame] )
	{
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
		beginCallButton.enabled = !inProgress && ([numberTextField.text length] != 0);
		
		endCallButton = [[self buttonWithTitle:endCallTitle] retain];
		endCallButton.hidden = !inProgress;
		
		clearNumberButton = [[self buttonWithTitle:clearNumberTitle] retain];
		clearNumberButton.hidden = inProgress;
		
		muteButton = [[self buttonWithTitle:muteTitle] retain];
		muteButton.enabled = NO;
		
		unmuteButton = [[self buttonWithTitle:unmuteTitle] retain];
		unmuteButton.hidden = YES;
	
		digitButtons = [[NSMutableArray alloc] initWithCapacity:12];
		for ( int i=0; i<NUM_DIGITS; ++i )
			[digitButtons addObject:[self buttonWithTitle:digitTitles[i]]];
			
		[self layoutSubviews];
	}
	return self;
}

-(void) dealloc
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	
	[digitButtons release];
	[unmuteButton release];
	[muteButton release];
	[endCallButton release];
	[beginCallButton release];
	[clearNumberButton release];
	[numberTextField release];
	[super dealloc];
}

#ifdef MACOSX
-(BOOL) isFlipped
{
	return YES;
}
#endif

-(void) updateButtonStates
{
	beginCallButton.enabled = !inCall && [numberTextField.text length] > 0;
	clearNumberButton.hidden = inCall;
	endCallButton.hidden = !inCall;
	muteButton.enabled = inCall;
	muteButton.hidden = muted;
	unmuteButton.enabled = inCall;
	unmuteButton.hidden = !muted;
}

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

@synthesize delegate;

@end
