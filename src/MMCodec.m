//
//  MMCodec.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

@implementation MMCodec

-(void) consumeData:(void *)data ofSize:(unsigned)size
{
	[self produceData:data ofSize:size];
}

@end
