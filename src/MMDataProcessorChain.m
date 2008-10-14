//
//  MMDataProcessorChain.m
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProcessorChain.h"

@interface MMDataProcessorChainEndpoint : MMDataProcessor
{
@private
	MMDataProcessorChain *processingChain;
}

-(id) initWithProcessingChain:(MMDataProcessorChain *)_processingChain;

@end

@implementation MMDataProcessorChainEndpoint

-(id) initWithProcessingChain:(MMDataProcessorChain *)_processingChain
{
	if ( self = [super init] )
	{
		// [pzion 20081014] We are owned by the processing chain
		// so we don't retain it
		processingChain = _processingChain;
	}
	return self;
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[processingChain produceData:data ofSize:size numSamples:numSamples];
}

@end

@implementation MMDataProcessorChain

-(id) init
{
	if ( self = [super init] )
	{
		lastConsumer = [[MMDataProcessorChainEndpoint alloc] initWithProcessingChain:self];
		firstConsumer = [lastConsumer retain];
	}
	return self;
}

-(void) dealloc
{
	[firstConsumer release];
	[lastConsumer release];
	[super dealloc];
}

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[firstConsumer consumeData:data ofSize:size numSamples:numSamples];
}

-(void) zap
{
	[firstConsumer release];
	firstConsumer = [lastConsumer retain];
}

-(void) pushDataProcessorOntoFront:(MMDataProcessor *)item
{
	[item connectToConsumer:firstConsumer];
	[firstConsumer release];
	firstConsumer = [item retain];
}

@end
