//
//  MMPhoneButton.m
//  MiuMiu
//
//  Created by Peter Zion on 22/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneButton.h"

@implementation MMPhoneButton

-(id) initWithTitle:(NSString *)title
{
	if ( self = [super init] )
	{
		button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		button.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
		button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		UIImage *backgroundImage = [[UIImage imageNamed:@"button.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		[button setBackgroundImage:backgroundImage forState:0];
		button.font = [UIFont boldSystemFontOfSize:24.0];
		[button setTitle:title forState:UIControlStateNormal];
		[button setTitleColor:[UIColor blackColor] forState:UIControlEventTouchDown];
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];	
		[button addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
		[button addTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

-(void) dealloc
{
	[button release];
	[super dealloc];
}

-(void) setPressTarget:(id)target action:(SEL)action
{
	pressTarget = target;
	pressAction = action;
}

-(void) setReleaseTarget:(id)target action:(SEL)action
{
	releaseTarget = target;
	releaseAction = action;
}

-(void) pressed:(id)sender
{
	[pressTarget performSelector:pressAction withObject:self];
}

-(void) released:(id)sender
{
	[releaseTarget performSelector:releaseAction withObject:self];
}

@dynamic view;
-(MMView *) view
{
	return button;
}

@dynamic enabled;
-(BOOL) enabled
{
	return button.enabled;
}
-(void) setEnabled:(BOOL)_
{
	button.enabled = _;
}

@dynamic hidden;
-(BOOL) hidden
{
	return button.hidden;
}
-(void) setHidden:(BOOL)_
{
	button.hidden = _;
}

@dynamic frame;
-(MMRect) frame
{
	return button.frame;
}
-(void) setFrame:(MMRect)_
{
	button.frame = _;
}

@dynamic title;
-(NSString *) title
{
	return [button titleForState:UIControlStateNormal];
}

@end
