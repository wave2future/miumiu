//
//  MMRingtoneGenerator.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMRingtoneGenerator.h"

#include "ringtone.h"

@implementation MMRingtoneGenerator

-(id) init
{
	if ( self = [super init] )
	{
		timer = [[NSTimer scheduledTimerWithTimeInterval:160.0/8000.0 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
	}
	return self;
}

-(void) dealloc
{
	[timer invalidate];
	[timer release];
	[super dealloc];
}

-(void) timerCallback:(id)_
{
	static const unsigned numSamples = 160;
	short samples[numSamples];
	for ( unsigned i=0; i<numSamples; ++i )
	{
		if ( timePosition % (6 * 8000) < 2 * 8000 )
			samples[i] = ringtone[timePosition%200];
		else
			samples[i] = 0;
		++timePosition;
	}
	[self produceData:samples ofSize:sizeof(samples)];
}

@end
