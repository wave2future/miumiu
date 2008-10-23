//
//  MMPhoneButton.m
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneButton.h"

@implementation MMPhoneButton

-(id) initWithTitle:(NSString *)title
{
	if ( self = [super init] )
	{
		button = [[NSButton alloc] init];
		[button setButtonType:NSMomentaryChangeButton];
		[button setTitle:title];
		[button setKeyEquivalent:title];
		[button setTarget:self];
		[button setAction:@selector(action:)];
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

-(void) action:(id)sender
{
	[pressTarget performSelector:pressAction withObject:self];
	[releaseTarget performSelector:releaseAction withObject:self afterDelay:0.125];
}

@dynamic view;
-(MMView *) view
{
	return button;
}

@dynamic enabled;
-(BOOL) enabled
{
	return [button isEnabled];
}
-(void) setEnabled:(BOOL)_
{
	[button setEnabled:_];
}

@dynamic hidden;
-(BOOL) hidden
{
	return [button isHidden];
}
-(void) setHidden:(BOOL)_
{
	[button setHidden:_];
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
	return [button title];
}

@end
