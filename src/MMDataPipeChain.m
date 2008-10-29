//
//  MMDataPipeChain.m
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPipeChain.h"

@interface MMDataPipeChainEndpoint : MMDataPipe
{
@protected
	MMDataPipeChain *dataPipeChain;
}

-(id) initWithDataPipeChain:(MMDataPipeChain *)_dataPipeChain;

@end

@implementation MMDataPipeChainEndpoint

-(id) initWithDataPipeChain:(MMDataPipeChain *)_dataPipeChain
{
	if ( self = [super init] )
	{
		dataPipeChain = _dataPipeChain;
	}
	return self;
}

-(void) respondToPullData:(void *)data ofSize:(unsigned)size
{
	if ( self.source != nil )
		[self pullData:data ofSize:size];
	else
		[dataPipeChain pullData:data ofSize:size];
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( self.target != nil )
		[self pushData:data ofSize:size numSamples:numSamples];
	else
		[dataPipeChain pushData:data ofSize:size numSamples:numSamples];
}

@end

@implementation MMDataPipeChain

-(id) init
{
	if ( self = [super init] )
	{
		[self zap];
	}
	return self;
}

-(void) dealloc
{
	[firstDataPipe release];
	[lastDataPipe release];
	[super dealloc];
}

-(void) respondToPullData:(void *)data ofSize:(unsigned)size
{
	if ( lastDataPipe != nil )
		[lastDataPipe respondToPullData:data ofSize:size];
	else
		[self pullData:data ofSize:size];
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	if ( firstDataPipe != nil )
		[firstDataPipe respondToPushData:data ofSize:size numSamples:numSamples];
	else
		[self pushData:data ofSize:size numSamples:numSamples];
}

-(void) zap
{
	[firstDataPipe release];
	firstDataPipe = [[MMDataPipeChainEndpoint alloc] initWithDataPipeChain:self];

	[lastDataPipe release];
	lastDataPipe = [[MMDataPipeChainEndpoint alloc] initWithDataPipeChain:self];
	
	[firstDataPipe connectToTarget:lastDataPipe];
}

-(void) pushDataPipeOntoFront:(MMDataPipe *)dataPipe
{
	MMDataPipe *oldFirstDataPipeTarget = firstDataPipe.target;
	[firstDataPipe connectToTarget:dataPipe];
	[dataPipe connectToTarget:oldFirstDataPipeTarget];
}

@end
