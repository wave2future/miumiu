//
//  MMNullProducer.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@interface MMNullProducer : MMDataProducer
{
@private
	unsigned samplesPerPacket;
	float timerInterval;
	NSTimer	*timer;
}

-(id) initWithSamplesPerPacket:(unsigned)_samplesPerPacket
	samplingFrequency:(float)samplingFrequency;

@end
