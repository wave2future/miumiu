//
//  MMSpeexDecoder.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMDecoder.h"

#include <speex/speex.h>

@interface MMSpeexDecoder : NSObject <MMDecoder>
{
@private
	SpeexBits bits; 
	void *dec_state;
	unsigned samplesPerFrame;
}

@end
