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

@implementation MMView

-(UIButton *) buttonWithTitle:(NSString *)title
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button setTitle:title forState:UIControlStateNormal];
	[button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
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
		numberTextField.returnKeyType = UIReturnKeyGo;
		numberTextField.enablesReturnKeyAutomatically = YES;
		numberTextField.keyboardType = UIKeyboardTypeEmailAddress;
		numberTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		numberTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		numberTextField.clearButtonMode = UITextFieldViewModeAlways;
		numberTextField.placeholder = @"Dial number then press Call";
		[self addSubview:numberTextField];
	
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

		NSString *oldText = numberTextField.text;
		if ( oldText != nil )
			numberTextField.text = [NSString stringWithFormat:@"%@%@", oldText, digit];
		else
			numberTextField.text = digit;
		
		beginCallButton.enabled = YES;
		[delegate view:self releasedDTMF:digit];
	}
}

-(void) didBeginCall:(id)sender
{
	if ( numberTextField.text != @"" )
	{
		beginCallButton.enabled = NO;
		clearNumberButton.hidden = YES;
		endCallButton.hidden = NO;
	}
}

-(void) didEndCall:(id)sender
{
	beginCallButton.enabled = NO;
	endCallButton.hidden = YES;
	clearNumberButton.hidden = NO;
	numberTextField.text = @"";
}

@synthesize delegate;

@end
