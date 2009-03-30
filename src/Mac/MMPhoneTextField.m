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
		textField = [[NSTextField alloc] init];
		textField.delegate = self;
		[textField setTextColor:[NSColor whiteColor]];
		[textField setBackgroundColor:[NSColor blackColor]];
		[textField setBezeled:NO];
		[textField setFont:[NSFont systemFontOfSize:17]];
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

@dynamic hidden;
-(BOOL) hidden
{
	return [textField isHidden];
}
-(void) setHidden:(BOOL)_
{
	[textField setHidden:_];
}

@synthesize delegate;

@end
