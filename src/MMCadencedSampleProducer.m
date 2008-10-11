//
//  MMRingProducer.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCadencedSampleProducer.h"

@implementation MMCadencedSampleProducer

-(id) initWithFrequency:(unsigned)_frequency samplesPerChunk:(unsigned)_samplesPerChunk sampleLoop:(const short *)_sampleLoop ofLength:(unsigned)_sampleLoopLen onSeconds:(float)onSeconds offSeconds:(float)offSeconds;
{
	if ( self = [super init] )
	{
		frequency = _frequency;
		samplesPerChunk = _samplesPerChunk;
		sampleLoop = _sampleLoop;
		sampleLoopLen = _sampleLoopLen;
		onSamples = roundf( onSeconds * frequency );
		offSamples = roundf( offSeconds * frequency );
		totalSamples = onSamples + offSamples;
	}
	return self;
}

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[super connectToConsumer:consumer];
	timer = [[NSTimer scheduledTimerWithTimeInterval:((float)samplesPerChunk/(float)frequency) target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
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
	unsigned dataSize = samplesPerChunk * sizeof(short);
	short *samples = alloca( dataSize );
	for ( unsigned i=0; i<samplesPerChunk; ++i )
	{
		if ( timePosition % totalSamples < onSamples )
			samples[i] = sampleLoop[timePosition%sampleLoopLen];
		else
			samples[i] = 0;
		++timePosition;
	}
	[self produceData:samples ofSize:dataSize];
}

@end
