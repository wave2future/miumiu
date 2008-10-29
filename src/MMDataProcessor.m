//
//  MMDataProcessor.m
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProcessor.h"

@implementation MMDataProcessor

-(void) respondToPullData:(void *)data ofSize:(unsigned)size numSamples:(unsigned *)numSamples
{
	[self pullData:data ofSize:size numSamples:numSamples];
	[self processData:data ofSize:size numSamples:numSamples];
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[self processData:data ofSize:size numSamples:&numSamples];
	[self pushData:data ofSize:size numSamples:numSamples];
}

-(void) processData:(void *)data ofSize:(unsigned)size numSamples:(unsigned *)numSamples
{
	@throw [NSException exceptionWithName:@"MMDataProcessor" reason:@"processData unspecialized" userInfo:nil];
}

@end
