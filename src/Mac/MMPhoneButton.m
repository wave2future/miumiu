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
		[self setButtonType:NSMomentaryLightButton];
		[self setTitle:title];
		[self setKeyEquivalent:title];
		[self setTarget:self];
		[self setAction:@selector(action:)];
	}
	return self;
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

-(void) mouseDown:(NSEvent *)theEvent
{
	NSPoint pointInWindow = [theEvent locationInWindow];
	NSPoint pointInView = [self convertPoint:pointInWindow fromView:nil];
	if ( NSPointInRect( pointInView, [self bounds] ) )
	{
		pressed = YES;
		[pressTarget performSelector:pressAction withObject:self];
	}
}

-(void) mouseUp:(NSEvent *)theEvent
{
	if ( pressed )
	{
		pressed = NO;
		[releaseTarget performSelector:releaseAction withObject:self];
	}
}

-(void) action:(id)sender
{
	[pressTarget performSelector:pressAction withObject:self];
	[releaseTarget performSelector:releaseAction withObject:self afterDelay:0.125];
}

@dynamic view;
-(MMView *) view
{
	return self;
}

@dynamic enabled;
@dynamic hidden;
@dynamic title;

@end
