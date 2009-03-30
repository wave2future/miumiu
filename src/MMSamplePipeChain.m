//
//  MMSamplePipeChain.m
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSamplePipeChain.h"
#import "MMSimpleSamplePipe.h"

@implementation MMSamplePipeChain

-(id) init
{
	if ( self = [super init] )
	{
		dataPipes = [[NSMutableArray alloc] init];
		[dataPipes addObject:[MMSimpleSamplePipe simpleDataPipe]];
	}
	return self;
}

-(void) dealloc
{
	[dataPipes release];
	[super dealloc];
}

#pragma mark Public

-(void) zap
{
	while ( [dataPipes count] > 1 )
	{
		id <MMSamplePipe> frontDataPipe = [dataPipes lastObject];
		[frontDataPipe disconnectFromSampleConsumer];
		[dataPipes removeLastObject];
	}
}

-(void) pushDataPipeOntoFront:(id <MMSamplePipe>)dataPipe
{
	id <MMSamplePipe> oldFrontDataPipe = [dataPipes lastObject];
	[dataPipe connectToSampleConsumer:oldFrontDataPipe];
	[dataPipes addObject:dataPipe];
}

#pragma mark MMSampleProducer

-(void) connectToSampleConsumer:(id <MMSampleConsumer>)consumer
{
	id <MMSamplePipe> lastDataPipe = [dataPipes objectAtIndex:0];
	[lastDataPipe connectToSampleConsumer:consumer];
}

-(id <MMSampleConsumer>) disconnectFromSampleConsumer
{
	id <MMSamplePipe> lastDataPipe = [[dataPipes objectAtIndex:0] retain];
	[lastDataPipe disconnectFromSampleConsumer];
	return [lastDataPipe autorelease];
}

#pragma mark MMSampleConsumer

-(void) reset
{
	id <MMSamplePipe> frontDataPipe = [dataPipes lastObject];
	[frontDataPipe reset];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	id <MMSamplePipe> frontDataPipe = [dataPipes lastObject];
	[frontDataPipe consumeSamples:samples count:count];
}

@end
