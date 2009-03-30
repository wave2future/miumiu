//
//  MMMuteInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 27/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMMuteInjector.h"

@implementation MMMuteInjector

#pragma mark Public

-(void) mute
{
	muted = YES;
}

-(void) unmute
{
	muted = NO;
}

#pragma mark MMSampleConsumer

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	if ( muted )
		memset( samples, 0, count*sizeof(short) );
	[super consumeSamples:samples count:count];
}

@end
