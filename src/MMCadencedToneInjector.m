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
		self.dataPipeDelegate = self;
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

-(void) processData:(void *)data ofSize:(unsigned)size
{
	unsigned numSamples = size/sizeof(short);
	if ( timePosition % totalSamples < onSamples )
	{
		[toneGenerator injectSamples:data count:numSamples offset:timePosition];
		timePosition += numSamples;
	}
	else
		timePosition = 0;
}

@end
