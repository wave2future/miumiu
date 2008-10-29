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
		self.dataPipeDelegate = self;
		samplesPerTick = _samplesPerTick;
		timerInterval = samplesPerTick / samplingFrequency;
	}
	return self;
}

-(void) dealloc
{
	[super dealloc];
}

-(void) dataPipe:(MMDataPipe *)dataPipe didConnectToTarget:(MMDataPipe *)newTarget
{
	timer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
	samplesSent = samplesNeeded = 0;
}

-(void) dataPipe:(MMDataPipe *)dataPipe willDisconnectFromTarget:(MMDataPipe *)oldTarget
{
	[timer invalidate];
	[timer release];
	timer = nil;
}

-(void) timerCallback:(id)_
{
	samplesNeeded += samplesPerTick;
	if ( samplesSent < samplesNeeded )
	{
		unsigned size = samplesPerTick * sizeof(short);
		short *data = alloca( size );
		memset( data, 0, size );

		while ( samplesSent < samplesNeeded )
		{
			[self pushData:data ofSize:size numSamples:samplesPerTick];
			samplesSent += samplesPerTick;
		}
	}
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[self pushData:data ofSize:size numSamples:numSamples];
	samplesSent += numSamples;
}
@end
