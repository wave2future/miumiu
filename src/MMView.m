//
//  MMView.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMView.h"

static NSString *beginCallTitle = @"Call", *endCallTitle = @"End", *clearNumberTitle = @"Clear";

#define NUM_DIGITS 12
static NSString *digitTitles[NUM_DIGITS] = { @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#" };
static NSString *buttonImageFile = @"button.png";

@implementation MMView

-(UIButton *) buttonWithTitle:(NSString *)title
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	UIImage *backgroundImage = [[UIImage imageNamed:buttonImageFile] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	[button setBackgroundImage:backgroundImage forState:0];
	button.font = [UIFont boldSystemFontOfSize:24.0];
	[button setTitle:title forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blackColor] forState:UIControlEventTouchDown];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];	
	[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
	[button addTarget:self action:@selector(buttonReleased:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:button];
	return button;
}

-(id) initWithNumber:(NSString *)number inProgress:(BOOL)inProgress;
{
	if ( self = [super init] )
	{
		numberTextField = [[UITextField alloc] init];
		numberTextField.text = number;
		numberTextField.textColor = [UIColor whiteColor];
		numberTextField.returnKeyType = UIReturnKeyDone;
		numberTextField.enablesReturnKeyAutomatically = NO;
		numberTextField.keyboardType = UIKeyboardTypeEmailAddress;
		numberTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		numberTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		numberTextField.clearButtonMode = UITextFieldViewModeNever;
		numberTextField.placeholder = @"Dial number then press Call";
		numberTextField.delegate = self;
		
		[self addSubview:numberTextField];
	
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
	
		digitButtons = [[NSMutableArray alloc] initWithCapacity:12];
		for ( int i=0; i<NUM_DIGITS; ++i )
			[digitButtons addObject:[self buttonWithTitle:digitTitles[i]]];
	}
	return self;
}

-(void) dealloc
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	
	[digitButtons release];
	[endCallButton release];
	[beginCallButton release];
	[clearNumberButton release];
	[numberTextField release];
	[super dealloc];
}

-(void) layoutSubviews
{
	CGRect bounds = self.bounds;
	
	numberTextField.frame = CGRectMake( CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetWidth(bounds), 60 );

	CGRect controlBounds = CGRectMake( CGRectGetMinX(bounds), CGRectGetMaxY(numberTextField.frame), CGRectGetWidth(bounds), 60 );
	beginCallButton.frame = CGRectMake( CGRectGetMinX(controlBounds), CGRectGetMinY(controlBounds), CGRectGetWidth(controlBounds)/2, CGRectGetHeight(controlBounds) );
	endCallButton.frame = CGRectMake( CGRectGetMaxX(beginCallButton.frame), CGRectGetMinY(controlBounds), CGRectGetMaxX(controlBounds) - CGRectGetMaxX(beginCallButton.frame), CGRectGetHeight(controlBounds) );
	clearNumberButton.frame = endCallButton.frame;
	
	CGRect digitsBounds = CGRectMake( CGRectGetMinX(bounds), CGRectGetMaxY(controlBounds), CGRectGetWidth(bounds), CGRectGetMaxY(bounds) - CGRectGetMaxY(controlBounds) );
	for ( int i=0; i<12; ++i )
	{
		int row = i/3, col = i%3;
		
		UIButton *digitButton = [digitButtons objectAtIndex:i];
		digitButton.frame = CGRectMake(
			roundf( CGRectGetMinX(digitsBounds) + col * CGRectGetWidth(digitsBounds) / 3 ),
			roundf( CGRectGetMinY(digitsBounds) + row * CGRectGetHeight(digitsBounds) / 4 ),
			roundf( CGRectGetWidth(digitsBounds) / 3 ),
			roundf( CGRectGetHeight(digitsBounds) / 4 ) );
	}
}

-(void) updateButtonStates
{
	beginCallButton.enabled = !inCall && [numberTextField.text length] > 0;
	clearNumberButton.hidden = inCall;
	endCallButton.hidden = !inCall;
}

-(void) buttonPressed:(UIButton *)button
{
	if ( button == beginCallButton )
		;
	else if ( button == endCallButton )
		;
	else if ( button == clearNumberButton )
		;
	else
	{
		NSString *digit = [button titleForState:UIControlStateNormal];

		NSString *oldText = numberTextField.text;
		if ( oldText != nil )
			numberTextField.text = [NSString stringWithFormat:@"%@%@", oldText, digit];
		else
			numberTextField.text = digit;
		
		[self updateButtonStates];

		[delegate view:self pressedDTMF:digit];
	}
}

-(void) buttonReleased:(UIButton *)button
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
	else
	{
		NSString *digit = [button titleForState:UIControlStateNormal];

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
	[self updateButtonStates];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

-(BOOL) textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string
{
	// [pzion 20081012] This is a pretty big hack: we want the button states to
	// update *after* the text is changed.
	[self performSelector:@selector(updateButtonStates) withObject:nil afterDelay:0.0];
	return YES;
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
