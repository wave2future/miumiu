//
//  MMPhoneLabel.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMPhoneLabel.h"

@implementation MMPhoneLabel

-(id) init
{
	if ( self = [super init] )
	{
		textField = [[NSTextField alloc] init];
		[textField setEditable:NO];
		[textField setTextColor:[NSColor greenColor]];
		[textField setBackgroundColor:[NSColor blackColor]];
		[textField setBezeled:NO];
	}
	return self;
}

-(void) dealloc
{
	[textField release];
	[super dealloc];
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

@end
