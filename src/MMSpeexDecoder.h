//
//  MMSpeexDecoder.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

#include <speex/speex.h>

@interface MMSpeexDecoder : MMCodec
{
@private
	SpeexBits bits; 
	void *dec_state;
	unsigned samplesPerFrame;
}

@end
