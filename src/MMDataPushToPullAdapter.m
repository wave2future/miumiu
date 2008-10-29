//
//  MMClock.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPushToPullAdapter.h"
#import "MMCircularBuffer.h"

@implementation MMDataPushToPullAdapter

-(id) initWithBufferCapacity:(unsigned)bufferCapacity
{
	if ( self = [super init] )
	{
		buffer = [[MMCircularBuffer alloc] initWithCapacity:bufferCapacity];
	}
	return self;
}

-(void) dealloc
{
	[buffer release];
	[super dealloc];
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[buffer putData:data ofSize:size];
}

-(void) respondToPullData:(void *)data ofSize:(unsigned)size
{
	if ( ![buffer getData:data ofSize:size] )
		memset( data, 0, size );
}

@end
