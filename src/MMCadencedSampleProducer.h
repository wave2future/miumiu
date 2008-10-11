//
//  MMRingProducer.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@class MMToneGenerator;

@interface MMCadencedSampleProducer : MMDataProducer
{
@private
	unsigned samplingFrequency;
	unsigned samplesPerChunk;
	MMToneGenerator *toneGenerator;
	unsigned onSamples, offSamples, totalSamples;
	NSTimer	*timer;
	unsigned timePosition;
}

-(id) initWithSamplingFrequency:(unsigned)_samplingFrequency
	samplesPerChunk:(unsigned)_samplesPerChunk
	numTones:(unsigned)numTones
	amplitudes:(const float *)amplitudes
	frequencies:(const float *)frequencies
	onSeconds:(float)onSeconds
	offSeconds:(float)offSeconds;

@end
