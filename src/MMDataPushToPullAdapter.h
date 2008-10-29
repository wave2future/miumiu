//
//  MMClock.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPipe.h"
#import "MMDataPipeDelegate.h"

@class MMCircularBuffer;

@interface MMDataPushToPullAdapter : MMDataPipe
{
@private
	MMCircularBuffer *buffer;
}

-(id) initWithBufferCapacity:(unsigned)bufferCapacity;

@end
