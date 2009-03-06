//
//  MMPhoneLabel.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneLabel.h"


@implementation MMPhoneLabel

-(id) init
{
	if ( self = [super init] )
	{
		label = [[UILabel alloc] init];
		label.textColor = [UIColor greenColor];
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = UITextAlignmentLeft;
	}
	return self;
}

-(void) dealloc
{
	[label release];
	[super dealloc];
}

@dynamic view;
-(MMView *) view
{
	return label;
}

@dynamic frame;
-(MMRect) frame
{
	return label.frame;
}
-(void) setFrame:(MMRect)_
{
	label.frame = _;
}

@dynamic text;
-(NSString *) text
{
	return label.text;
}
-(void) setText:(NSString *)_
{
	label.text = _;
}

@end
