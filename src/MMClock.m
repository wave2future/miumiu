//
//  MMClock.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMClock.h"
#import "MMCircularBuffer.h"

@implementation MMClock

-(id) initWithSamplesPerTick:(unsigned)_samplesPerTick
	samplingFrequency:(float)samplingFrequency
{
	if ( self = [super init] )
	{
		samplesPerTick = _samplesPerTick;
		timerInterval = samplesPerTick / samplingFrequency;
		buffer = [[MMCircularBuffer alloc] initWithCapacity:(4*samplesPerTick*sizeof(short))];
	}
	return self;
}

-(void) dealloc
{
	[buffer release];
	[super dealloc];
}

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[super connectToConsumer:consumer];
	
	timer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
	samplesSent = samplesNeeded = 0;
	[buffer zap];
}

-(void) disconnect
{
	[timer invalidate];
	[timer release];
	timer = nil;
	
	[super disconnect];
}

-(void) timerCallback:(id)_
{
	samplesNeeded += samplesPerTick;
	if ( samplesSent < samplesNeeded )
	{
		unsigned size = samplesPerTick * sizeof(short);
		short *data = alloca( size );

		while ( samplesSent < samplesNeeded )
		{
			if ( ![buffer getData:data ofSize:size] )
				memset( data, 0, size );
			[self produceData:data ofSize:size numSamples:samplesPerTick];
			samplesSent += samplesPerTick;
		}
	}
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( samplesSent + numSamples <= samplesNeeded )
	{
		[self produceData:data ofSize:size numSamples:numSamples];
		samplesSent += numSamples;
	}
	else
		[buffer putData:data ofSize:size];
}
@end
