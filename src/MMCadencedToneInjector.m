//
//  MMRingInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCadencedToneInjector.h"
#import "MMToneGenerator.h"

@implementation MMCadencedToneInjector

-(id) initWithSamplingFrequency:(unsigned)_samplingFrequency
	numTones:(unsigned)numTones
	amplitudes:(const float *)amplitudes
	frequencies:(const float *)frequencies
	onSeconds:(float)onSeconds
	offSeconds:(float)offSeconds
{
	if ( self = [super init] )
	{
		samplingFrequency = _samplingFrequency;
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
	
	timePosition = 0;
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples;
{
	if ( timePosition % totalSamples < onSamples )
		[toneGenerator injectSamples:data count:numSamples offset:timePosition];
	timePosition += numSamples;

	[self produceData:data ofSize:size numSamples:numSamples];
}

@end
