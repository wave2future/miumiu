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
		textField = [[NSTextField alloc] init];
		textField.delegate = self;
	}
	return self;
}

-(void) dealloc
{
	[textField release];
	[super dealloc];
}

-(void) textDidChange:(NSNotification *)aNotification
{
	if ( [delegate respondsToSelector:@selector(textFieldDidChange:)] )
		[delegate textFieldDidChange:self];
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
	return [textField stringValue];
}
-(void) setText:(NSString *)_
{
	[textField setStringValue:_];
}

@synthesize delegate;

@end
