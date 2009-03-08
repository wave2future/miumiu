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

#pragma mark Initialization

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

#pragma mark MMSampleConsumer

-(void) reset
{
	timePosition = 0;
}

-(void) consumeSamples:(void *)samples count:(unsigned)count
{
	if ( timePosition < onSamples )
		[toneGenerator injectSamples:samples count:count offset:timePosition];
	timePosition += count;
	while ( timePosition > totalSamples )
		timePosition -= totalSamples;
	[super consumeSamples:samples count:count];
}

@end
