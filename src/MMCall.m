//
//  MMCall.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCall.h"

@implementation MMCall

-(id) initWithCallDelegate:(id <MMCallDelegate>)_delegate
{
	if ( self = [super init] )
	{
		self.delegate = _delegate;
	}
	return self;
}

-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples
{
}

-(void) sendDTMF:(NSString *)dtmf
{
}

-(void) end
{
}

@synthesize delegate;

@end
