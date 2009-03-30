//
//  MMSimpleSamplePipe.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

@implementation MMSimpleSamplePipe

-(void) dealloc
{
	[connectedConsumer release];
	[super dealloc];
}

+(id) simpleDataPipe
{
	return [[[MMSimpleSamplePipe alloc] init] autorelease];
}

#pragma mark MMSampleProducer

-(void) connectToSampleConsumer:(id <MMSampleConsumer>)consumer
{
	[self disconnectFromSampleConsumer];
	connectedConsumer = [consumer retain];
}

-(id <MMSampleConsumer>) disconnectFromSampleConsumer
{
	id <MMSampleConsumer> result = [connectedConsumer autorelease];
	connectedConsumer = nil;
	return result;
}

#pragma mark MMSampleConsumer

-(void) reset
{
	[connectedConsumer reset];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	[connectedConsumer consumeSamples:samples count:count];
}

@end
