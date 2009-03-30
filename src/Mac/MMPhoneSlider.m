//
//  MMPhoneSlider.m
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMPhoneSlider.h"
#import "MMPhoneSliderDelegate.h"

@implementation MMPhoneSlider

-(id) init
{
	if ( self = [super init] )
	{
		slider = [[NSSlider alloc] init];
		[slider setMinValue:0.0];
		[slider setMaxValue:1.0];
		[slider setTarget:self];
		[slider setAction:@selector(sliderDidChange:)];
	}
	return self;
}

-(void) dealloc
{
	[slider release];
	[super dealloc];
}

-(void) sliderDidChange:(id)sender
{
	[delegate phoneSlider:self didChangeValueTo:[slider floatValue]];
}

@dynamic view;
-(MMView *) view
{
	return slider;
}

@dynamic frame;
-(MMRect) frame
{
	return slider.frame;
}
-(void) setFrame:(MMRect)_
{
	slider.frame = _;
}

@synthesize delegate;

@dynamic value;
-(float) value
{
	return [slider floatValue];
}
-(void) setValue:(float)_
{
	[slider setFloatValue:_];
}

@end
