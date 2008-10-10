//
//  MMSpeexDecoder.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMCodec.h"
#include <speex/speex.h>

@interface MMSpeexDecoder : MMCodec
{
@private
	BOOL running;
	SpeexBits bits; 
	void *dec_state; 
	spx_int32_t frameSize;
	spx_int16_t *frame;
}

-(void) start;
-(void) fromBuffer:(MMCircularBuffer *)src toBuffer:(MMCircularBuffer *)dst;
-(void) stop;

@end
