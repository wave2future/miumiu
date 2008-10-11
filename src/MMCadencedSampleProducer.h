//
//  MMRingProducer.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

@class MMToneGenerator;

@interface MMCadencedSampleProducer : MMCodec
{
@private
	unsigned samplingFrequency;
	MMToneGenerator *toneGenerator;
	unsigned onSamples, offSamples, totalSamples;
	unsigned timePosition;
}

-(id) initWithSamplingFrequency:(unsigned)_samplingFrequency
	numTones:(unsigned)numTones
	amplitudes:(const float *)amplitudes
	frequencies:(const float *)frequencies
	onSeconds:(float)onSeconds
	offSeconds:(float)offSeconds;

@end
