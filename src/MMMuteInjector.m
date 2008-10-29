//
//  MMMuteInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 27/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMMuteInjector.h"

@implementation MMMuteInjector

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( muted )
	{
		void *mutedData = alloca( size );
		memset( mutedData, 0, size );
		return [self pushData:mutedData ofSize:size numSamples:numSamples];
	}
	return [self pushData:data ofSize:size numSamples:numSamples];
}

-(void) mute
{
	muted = YES;
}

-(void) unmute
{
	muted = NO;
}

@end
