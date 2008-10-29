//
//  MMMuteInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 27/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMMuteInjector.h"

@implementation MMMuteInjector

-(void) processData:(void *)data ofSize:(unsigned)size
{
	if ( muted )
		memset( data, 0, size );
}

-(void) mute
{
	muted = YES;
}

-(void) unmute
{
	muted = NO;
}

@end
