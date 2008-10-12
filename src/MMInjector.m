//
//  MMInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMInjector.h"

@implementation MMInjector

-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
	[self produceData:data ofSize:size numSamples:numSamples];
}

@end
