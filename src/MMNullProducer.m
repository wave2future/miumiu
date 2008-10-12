//
//  MMNullProducer.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMNullProducer.h"

@implementation MMNullProducer

-(id) initWithSamplesPerPacket:(unsigned)_samplesPerPacket
	samplingFrequency:(float)samplingFrequency
{
	if ( self = [super init] )
	{
		samplesPerPacket = _samplesPerPacket;
		timerInterval = samplesPerPacket / samplingFrequency;
	}
	return self;
}

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[super connectToConsumer:consumer];
	
	timer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES] retain];
}

-(void) disconnect
{
	[timer invalidate];
	[timer release];
	timer = nil;
	
	[super disconnect];
}

-(void) timerCallback:(id)_
{
	unsigned dataSize = samplesPerPacket * sizeof(short);
	short *samples = alloca( dataSize );

	memset( samples, 0, dataSize );

	[self produceData:samples ofSize:dataSize numSamples:samplesPerPacket];
}

@end
