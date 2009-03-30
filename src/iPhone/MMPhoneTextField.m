//
//  MMPhoneTextField.m
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMPhoneTextField.h"

@implementation MMPhoneTextField

-(id) init
{
	if ( self = [super init] )
	{
		textField = [[UITextField alloc] init];
		textField.delegate = self;
		textField.textColor = [UIColor yellowColor];
		textField.font = [UIFont boldSystemFontOfSize:28.0];
		textField.returnKeyType = UIReturnKeyDone;
		textField.enablesReturnKeyAutomatically = NO;
		textField.keyboardType = UIKeyboardTypeEmailAddress;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textField.clearButtonMode = UITextFieldViewModeNever;
		textField.placeholder = @"Dial then press Call";
	}
	return self;
}

-(void) dealloc
{
	[textField release];
	[super dealloc];
}

-(BOOL) textFieldShouldReturn:(UITextField *)_textField
{
	[textField resignFirstResponder];
	return YES;
}

-(void) informDelegateThatTextFieldDidChange
{
	if ( [delegate respondsToSelector:@selector(textFieldDidChange:)] )
		[delegate performSelector:@selector(textFieldDidChange:) withObject:self];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	// [pzion 20090305] editing is annoying.  Turn it off.
	return NO;
}

-(BOOL) textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string
{
	[self performSelector:@selector(informDelegateThatTextFieldDidChange) withObject:nil afterDelay:0.0];
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

@dynamic hidden;
-(BOOL) hidden
{
	return textField.hidden;
}
-(void) setHidden:(BOOL)_
{
	textField.hidden = _;
}

@synthesize delegate;

@end
