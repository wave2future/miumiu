//
//  MMPhoneTextField.m
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneTextField.h"

@implementation MMPhoneTextField

-(id) init
{
	if ( self = [super init] )
	{
		textField = [[UITextField alloc] init];
		textField.delegate = self;
		textField.textColor = [UIColor whiteColor];
		textField.returnKeyType = UIReturnKeyDone;
		textField.enablesReturnKeyAutomatically = NO;
		textField.keyboardType = UIKeyboardTypeEmailAddress;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textField.clearButtonMode = UITextFieldViewModeNever;
		textField.placeholder = @"Dial number then press Call";
	}
	return self;
}

-(void) dealloc
{
	[textField release];
	[super dealloc];
}

-(void) resignFirstResponder
{
	[textField resignFirstResponder];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
	if ( [delegate respondsToSelector:@selector(textFieldShouldReturn:)] )
		return [delegate textFieldShouldReturn:self];
	else
		return YES;
}

-(BOOL) textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string
{
	if ( [delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] )
		return [delegate textField:self shouldChangeCharactersInRange:range replacementString:string];
	else
		return YES;
}

@dynamic view;
-(MMView *) view
{
	return textField;
}

@dynamic frame;
-(MMRect) frame
{
	return textField.frame;
}
-(void) setFrame:(MMRect)_
{
	textField.frame = _;
}

@dynamic text;
-(NSString *) text
{
	return textField.text;
}
-(void) setText:(NSString *)_
{
	textField.text = _;
}

@synthesize delegate;

@end
