//
//  MMPhoneLevel.m
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneLevel.h"

@implementation MMPhoneLevel

-(id) init
{
	if ( self = [super init] )
	{
	}
	return self;
}

-(void) drawRect:(CGRect)rect
{
	CGRect boundsRect = self.bounds;
	
	UIColor *levelColor;
	value = (float) roundf( 10 * value ) / 10;
	if ( value >= 0.8 )
		levelColor = [UIColor redColor];
	else if ( value >= 0.6 )
		levelColor = [UIColor yellowColor];
	else
		levelColor = [UIColor greenColor];
	CGRect levelRect = CGRectMake( CGRectGetMinX(boundsRect), CGRectGetMinY(boundsRect), value*CGRectGetWidth(boundsRect), CGRectGetHeight(boundsRect) );
	
	UIColor *backgroundColor = [UIColor blackColor];
	CGRect backgroundRect = CGRectMake( CGRectGetMaxX(levelRect), CGRectGetMinY(boundsRect), CGRectGetMaxX(boundsRect) - CGRectGetMaxX(levelRect), CGRectGetHeight(boundsRect) );
	
	[levelColor set];
	UIRectFill( levelRect );
	[backgroundColor set];
	UIRectFill( backgroundRect );
}

@dynamic view;
-(MMView *) view
{
	return self;
}

@dynamic value;
-(float) value
{
	return value;
}
-(void) setValue:(float)_
{
	value = _;
	[self setNeedsDisplay];
}

@end
