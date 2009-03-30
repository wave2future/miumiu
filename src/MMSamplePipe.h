/*
 *  MMSamplePipe.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 Peter Zion. All rights reserved.
 *
 */

#import "MMSampleProducer.h"
#import "MMSampleConsumer.h"

@protocol MMSamplePipe <MMSampleProducer, MMSampleConsumer>
@end
