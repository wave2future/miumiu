//
//  MMCircularBuffer.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCircularBuffer.h"

@implementation MMCircularBuffer

-(id) init
{
	if ( self = [super init] )
	{
		size = 1024;
		maxSize = 65536;
		speexBuffer = speex_buffer_init( size );
	}
	return self;
}

-(void) dealloc
{
	speex_buffer_destroy( speexBuffer );
	[super dealloc];
}

-(BOOL) putData:(const void *)buffer ofSize:(unsigned)count
{
	if ( count == 0 )
		return YES;

	unsigned newUsed = self.used + count;
	if ( newUsed > size )
	{
		if ( newUsed > maxSize )
			return NO;

		speex_buffer_resize( speexBuffer, size = newUsed );
	}

	return speex_buffer_write( speexBuffer, (void *)buffer, count ) == count;
}

-(BOOL) getData:(void *)buffer ofSize:(unsigned)count
{
	if ( self.used < count )
		return NO;
	
	return speex_buffer_read( speexBuffer, buffer, count ) == count;
}

@synthesize size;

@dynamic used;
-(unsigned) used
{
	return speex_buffer_get_available( speexBuffer );
}

@end
