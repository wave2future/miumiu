//
//  MMDataProducer.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@implementation MMDataProducer

-(void) dealloc
{
	[self disconnect];
	[super dealloc];
}

-(void) produceData:(void *)data ofSize:(unsigned)size
{
	if ( size > 0 )
		[connectedConsumer consumeData:data ofSize:size];
}

-(void) connectToConsumer:(id <MMDataConsumer>)consumer
{
	[connectedConsumer autorelease];
	connectedConsumer = [consumer retain];
}

-(void) disconnect
{
	[connectedConsumer release];
	connectedConsumer = nil;
}

@end
