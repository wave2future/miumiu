//
//  MMIAXCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"
#import "MMCall.h"
#import "MMEncoderTarget.h"
#import "MMDecoderTarget.h"

#include <iax-client.h>

@class MMIAX;
@protocol MMEncoder;
@protocol MMDecoder;
@protocol MMCallDelegate;

@interface MMIAXCall : MMSimpleSamplePipe <MMCall, MMEncoderTarget, MMDecoderTarget>
{
@private
	id <MMCallDelegate> delegate;
	MMIAX *iax;
	struct iax_session *session;
	BOOL wasAccepted;
	unsigned format;
	id <MMEncoder> encoder;
	id <MMDecoder> decoder;
}

#pragma mark Initialization

-(id) initWithSession:(struct iax_session *)session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax;
-(id) initWithFormat:(unsigned)_format session:(struct iax_session *)session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax;

#pragma mark Public

-(BOOL) handleEvent:(struct iax_event *)event;

@end
