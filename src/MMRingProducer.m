//
//  MMRingProducer.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMRingProducer.h"

@implementation MMRingProducer

-(id) init
{
	static const unsigned count = 2;
	static const short amplitudes[] = { 16384, 16384 };
	static const unsigned frequencies[] = { 440, 480 };
	return [super initWithFrequency:8000
		samplesPerChunk:160
		amplitudes:amplitudes
		frequencies:frequencies
		count:count
		onSeconds:2
		offSeconds:4];
}

@end
