//
//  MMClock.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@class MMCircularBuffer;

@interface MMClock : MMDataProducer <MMDataConsumer>
{
@private
	unsigned samplesPerTick;
	float timerInterval;
	NSTimer	*timer;
	MMCircularBuffer *buffer;
	unsigned samplesSent, samplesNeeded;
}

-(id) initWithSamplesPerTick:(unsigned)_samplesPerTick
	samplingFrequency:(float)samplingFrequency;

@end
