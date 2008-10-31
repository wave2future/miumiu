//
//  MMPhoneSlider.m
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneSlider.h"
#import "MMPhoneSliderDelegate.h"

@implementation MMPhoneSlider

-(id) init
{
	if ( self = [super init] )
	{
		slider = [[UISlider alloc] init];
		slider.minimumValue = 0.0;
		slider.maximumValue = 1.0;
		[slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
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
	[delegate phoneSlider:self didChangeValueTo:slider.value];
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
	return slider.value;
}
-(void) setValue:(float)_
{
	slider.value = _;
}

@end
