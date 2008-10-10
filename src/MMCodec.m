//
//  MMCodec.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

@implementation MMCodec

-(void) dealloc
{
	[self stop];
	[super dealloc];
}

-(void) start
{
}

-(void) fromBuffer:(MMCircularBuffer *)src toBuffer:(MMCircularBuffer *)dst
{
	static const unsigned bufferSize = 256;
	char buffer[bufferSize];
	while ( [src getData:buffer ofSize:bufferSize] )
		[dst putData:buffer ofSize:bufferSize];
}

-(void) stop
{
}

@end
