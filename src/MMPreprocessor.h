//
//  MMPreprocessor.h
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

#include <speex/speex_preprocess.h>

@interface MMPreprocessor : MMSimpleSamplePipe
{
@private
	SpeexPreprocessState *state;
}

@end
