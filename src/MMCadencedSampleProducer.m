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

-(id) initWithSamplingFrequency:(unsigned)_samplingFrequency
	samplesPerChunk:(unsigned)_samplesPerChunk
	numTones:(unsigned)numTones
	amplitudes:(const float *)amplitudes
	frequencies:(const float *)frequencies
	onSeconds:(float)onSeconds
	offSeconds:(float)offSeconds
{
	if ( self = [super init] )
	{
		samplingFrequency = _samplingFrequency;
		samplesPerChunk = _samplesPerChunk;
		onSamples = roundf( onSeconds * samplingFrequency );
		toneGenerator = [[MMToneGenerator alloc] initWithNumTones:numTones
			amplitudes:amplitudes
			frequencies:frequencies
			samplingFrequency:samplingFrequency];
		offSamples = roundf( offSeconds * samplingFrequency );
		totalSamples = onSamples + offSamples;
	}
	return self;
}

-(void) dealloc
{
	[toneGenerator release];
	[super dealloc];
}

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[super connectToConsumer:consumer];
	timer = [[NSTimer scheduledTimerWithTimeInterval:((float)samplesPerChunk/(float)samplingFrequency) target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
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

	if ( timePosition % totalSamples < onSamples )
		[toneGenerator generateSamples:samples count:samplesPerChunk offset:timePosition];
	else
		memset( samples, 0, dataSize );
	timePosition += samplesPerChunk;

	[self produceData:samples ofSize:dataSize];
}

@end
