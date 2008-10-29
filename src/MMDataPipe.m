//
//  MMDataPipe.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPipe.h"
#import "MMDataPipeDelegate.h"

@implementation MMDataPipe

-(void) dealloc
{
	[self disconnectFromSource];
	[self disconnectFromTarget];
	[super dealloc];
}

@synthesize dataPipeDelegate;

@synthesize source;

@synthesize target;

-(void) connectToSource:(MMDataPipe *)newSource
{
	if ( source != newSource )
	{	
		if ( source != nil )
		{
			MMDataPipe *oldSource = source;
			if ( [dataPipeDelegate respondsToSelector:@selector(dataPipe:willDisconnectFromSource:)] )
				[dataPipeDelegate dataPipe:self willDisconnectFromSource:oldSource];
			[source autorelease];
			source = nil;
			[oldSource disconnectFromSource];
		}
		
		if ( newSource != nil )
		{
			source = [newSource retain];
			[newSource connectToSource:self];
			if ( [dataPipeDelegate respondsToSelector:@selector(dataPipe:didConnectToSource:)] )
				[dataPipeDelegate dataPipe:self didConnectToSource:newSource];
		}
	}
}

-(void) didConnectToSource:(MMDataPipe *)newSource
{
}

-(void) pullData:(void *)data ofSize:(unsigned)size numSamples:(unsigned *)numSamples
{
	[source respondToPullData:data ofSize:size numSamples:numSamples];
}

-(void) respondToPullData:(void *)data ofSize:(unsigned)size numSamples:(unsigned *)numSamples
{
	@throw [NSException exceptionWithName:@"MMDataPipe" reason:@"respondToPullData unspecialize" userInfo:nil];
}

-(void) willDisconnectFromSource:(MMDataPipe *)oldSource
{
}

-(void) disconnectFromSource
{
	[self connectToSource:nil];
}

-(void) connectToTarget:(MMDataPipe *)newTarget
{
	if ( target != newTarget )
	{	
		if ( target != nil )
		{
			MMDataPipe *oldTarget = target;
			if ( [dataPipeDelegate respondsToSelector:@selector(dataPipe:willDisconnectFromTarget:)] )
				[dataPipeDelegate dataPipe:self willDisconnectFromTarget:oldTarget];
			[target autorelease];
			target = nil;
			[oldTarget disconnectFromSource];
		}
		
		if ( newTarget != nil )
		{
			target = [newTarget retain];
			[newTarget connectToSource:self];
			if ( [dataPipeDelegate respondsToSelector:@selector(dataPipe:didConnectToTarget:)] )
				[dataPipeDelegate dataPipe:self didConnectToTarget:newTarget];
		}
	}
}

-(void) pushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[target respondToPushData:data ofSize:size numSamples:numSamples];
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	@throw [NSException exceptionWithName:@"MMDataPipe" reason:@"respondToPushData unspecialize" userInfo:nil];
}

-(void) disconnectFromTarget
{
	[self connectToTarget:nil];
}

@end
