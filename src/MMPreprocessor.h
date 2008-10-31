//
//  MMPreprocessor.h
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProcessor.h"
#import "MMDataPipeDelegate.h"

#include <speex/speex_preprocess.h>

@interface MMPreprocessor : MMDataProcessor <MMDataPipeDelegate>
{
@private
	SpeexPreprocessState *state;
}

@end
