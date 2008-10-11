//
//  MMRingProducer.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCadencedSampleProducer.h"
#import "MMToneGenerator.h"

@implementation MMCadencedSampleProducer

-(id) initWithFrequency:(unsigned)_frequency
	samplesPerChunk:(unsigned)_samplesPerChunk
	amplitudes:(const short *)amplitudes
	frequencies:(const unsigned *)frequencies
	count:(unsigned)count
	onSeconds:(float)onSeconds
	offSeconds:(float)offSeconds
{
	if ( self = [super init] )
	{
		frequency = _frequency;
		samplesPerChunk = _samplesPerChunk;
		onSamples = roundf( onSeconds * frequency );
		loop = [[MMToneGenerator generateSampleForAmplitudes:amplitudes
			frequencies:frequencies
			count:count
			numSamples:onSamples
			samplingFrequency:frequency] retain];
		offSamples = roundf( offSeconds * frequency );
		totalSamples = onSamples + offSamples;
	}
	return self;
}

-(void) dealloc
{
	[loop release];
	[super dealloc];
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
	const short *sampleLoop = [loop bytes];
	
	unsigned dataSize = samplesPerChunk * sizeof(short);
	short *samples = alloca( dataSize );
	for ( unsigned i=0; i<samplesPerChunk; ++i )
	{
		unsigned loopTimePosition = timePosition % totalSamples;
		if ( loopTimePosition < onSamples )
			samples[i] = sampleLoop[loopTimePosition];
		else
			samples[i] = 0;
		++timePosition;
	}
	[self produceData:samples ofSize:dataSize];
}

@end
