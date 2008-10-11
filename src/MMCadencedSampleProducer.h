//
//  MMRingProducer.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@interface MMCadencedSampleProducer : MMDataProducer
{
@private
	unsigned frequency;
	unsigned samplesPerChunk;
	const short *sampleLoop;
	unsigned sampleLoopLen;
	unsigned onSamples, offSamples, totalSamples;
	NSTimer	*timer;
	unsigned timePosition;
}

-(id) initWithFrequency:(unsigned)_frequency samplesPerChunk:(unsigned)_samplesPerChunk sampleLoop:(const short *)_sampleLoop ofLength:(unsigned)_sampleLoopLen onSeconds:(float)onSeconds offSeconds:(float)offSeconds;

@end
