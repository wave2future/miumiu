//
//  MMSpeexEncoder.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMDataProducer.h"
#import "MMDataConsumer.h"
#import "MMCircularBuffer.h"
#include <speex/speex.h>

@interface MMSpeexEncoder : MMDataProducer <MMDataConsumer>
{
@private
	BOOL running;
	SpeexBits bits; 
	void *enc_state;
	spx_int32_t frameSize;
	MMCircularBuffer *buffer;
}

-(void) start;
-(void) stop;

@end
