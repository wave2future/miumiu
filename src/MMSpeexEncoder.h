//
//  MMSpeexEncoder.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMEncoder.h"

#include <speex/speex.h>

@class MMCircularBuffer;

@interface MMSpeexEncoder : NSObject <MMEncoder>
{
@private
	SpeexBits bits; 
	void *enc_state;
	unsigned samplesPerFrame;
	MMCircularBuffer *buffer;
}

@end
