//
//  MMClock.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@interface MMClock : MMDataProducer <MMDataConsumer>
{
@private
	unsigned samplesPerTick;
	float timerInterval;
	NSTimer	*timer;
	unsigned samplesSent, samplesNeeded;
}

-(id) initWithSamplesPerTick:(unsigned)_samplesPerTick
	samplingFrequency:(float)samplingFrequency;

@end
