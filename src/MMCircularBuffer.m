//
//  MMCircularBuffer.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCircularBuffer.h"

@implementation MMCircularBuffer

-(id) initWithCapacity:(unsigned)_capacity
{
	if ( self = [super init] )
	{
		capacity = _capacity;
		buffer = malloc( capacity );
		head = 0;
		used = 0;
	}
	return self;
}

-(void) dealloc
{
	free( buffer );
	[super dealloc];
}

-(BOOL) putData:(const void *)_data ofSize:(unsigned)size
{
	if ( used + size > capacity )
		return NO;

	const char *data = _data;
	while ( size > 0 )
	{
		unsigned tail = head + used;
		if ( tail >= capacity )
			tail -= capacity;
			
		unsigned chunk = size;
		if ( tail + chunk >= capacity )
			chunk = capacity - tail;
			
		memcpy( &buffer[tail], data, chunk );
		data += chunk;
		size -= chunk;
		
		used += chunk;
	}
	
	return YES;
}

-(BOOL) getData:(void *)_data ofSize:(unsigned)size
{
	if ( used < size )
		return NO;
	
	char *data = _data;
	while ( size > 0 )
	{
		unsigned chunk = size;
		if ( head + chunk >= capacity )
			chunk = capacity - head;
			
		memcpy( data, &buffer[head], chunk );
		data += chunk;
		size -= chunk;
		
		head += chunk;
		if ( head == capacity )
			head = 0;
		used -= chunk;
	}
	
	return YES;
}

-(void) zap
{
	used = 0;
}

@synthesize capacity;
@synthesize used;

@end
