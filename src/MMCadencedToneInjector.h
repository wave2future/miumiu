//
//  MMRingInjector.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

@class MMToneGenerator;

@interface MMCadencedToneInjector : MMSimpleSamplePipe
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
