//
//  MMCircularBuffer.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <speex/speex_buffer.h>

@interface MMCircularBuffer : NSObject
{
@private
	SpeexBuffer *speexBuffer;
	unsigned size, maxSize;
}

-(BOOL) putData:(const void *)buffer ofSize:(unsigned)size;
-(BOOL) getData:(void *)buffer ofSize:(unsigned)size;

@property ( nonatomic, readonly ) unsigned size;
@property ( nonatomic, readonly ) unsigned used;

@end
